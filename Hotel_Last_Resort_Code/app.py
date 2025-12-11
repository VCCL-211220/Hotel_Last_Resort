# Modified by Abel: Added queries route with 8 management queries, fixed room_revenue calculations
from flask import Flask, render_template, request, redirect, url_for
from datetime import datetime
import sqlite3
from datetime import date

app = Flask(__name__)

def get_db_connection():
    conn = sqlite3.connect("database2.db",timeout=10)
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/')
def home():
    return render_template("index.html")



@app.route("/employee-login", methods=["GET", "POST"])
def employee_login():
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]

        conn = get_db_connection()
        cur = conn.cursor()

        # Query DB for matching username + password
        cur.execute("""
            SELECT * FROM employee_login
            WHERE employeeUserName = ? AND employeePassword = ?
        """, (username, password))

        user = cur.fetchone()
        conn.close()

        if user:
            # SUCCESS → Go to dashboard
            return redirect(url_for("dashboard"))
        else:
            # FAIL → Show error message
            return render_template(
                "login.html",
                error="Invalid username or password."
            )

    # GET request
    return render_template("login.html")


@app.route("/rooms-status")
def rooms_status():
    status = (request.args.get("status") or "").strip()
    room_type = (request.args.get("type") or "").strip()
    wing = (request.args.get("wing") or "").strip()
    search = (request.args.get("search") or "").strip()

    conn = sqlite3.connect("database2.db")   # keep your DB name
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    # ---- dropdown values ----
    # all possible status names
    cur.execute("SELECT DISTINCT statusName FROM room_status ORDER BY statusName")
    unique_statuses = [row["statusName"] for row in cur.fetchall()]

    # all room type labels
    cur.execute("SELECT DISTINCT sizeLabel FROM room_type ORDER BY sizeLabel")
    unique_types = [row["sizeLabel"] for row in cur.fetchall()]

    # all wing names
    cur.execute("SELECT DISTINCT wingName FROM wing ORDER BY wingName")
    unique_wings = [row["wingName"] for row in cur.fetchall()]

    # ---- main query ----
    # we build a derived table "ws" that contains the *latest* status per room
    base_sql = """
        SELECT
            r.roomNumber,
            rt.sizeLabel        AS roomType,
            ws.statusName       AS status,
            w.wingName          AS wing,
            ws.statusName       AS roomStatus,
            CASE
                WHEN ws.statusName IN ('Being Cleaned','Under Maintenance','Out of Service')
                    THEN 'Needs Attention'
                WHEN ws.statusName IN ('Ready for Check-in','Available')
                    THEN 'Ready'
                ELSE 'Unknown'
            END                 AS housekeepingStatus
        FROM room r
        JOIN floor f
          ON r.floorID = f.floorID
        JOIN wing w
          ON f.wingID = w.wingID
        JOIN room_type rt
          ON r.roomTypeID = rt.roomTypeID
        LEFT JOIN (
            SELECT ra.roomID, rs.statusName
            FROM room_availability ra
            JOIN room_status rs
              ON ra.statusID = rs.statusID
            WHERE ra.timestamp = (
                SELECT MAX(timestamp)
                FROM room_availability ra2
                WHERE ra2.roomID = ra.roomID
            )
        ) ws
          ON ws.roomID = r.roomID
        WHERE 1 = 1
    """

    params = []

    # apply filters
    if status:
        base_sql += " AND ws.statusName = ?"
        params.append(status)

    if room_type:
        base_sql += " AND rt.sizeLabel = ?"
        params.append(room_type)

    if wing:
        base_sql += " AND w.wingName = ?"
        params.append(wing)

    if search:
        base_sql += " AND r.roomNumber LIKE ?"
        params.append(f"%{search}%")

    base_sql += " ORDER BY w.wingName, r.roomNumber"

    cur.execute(base_sql, params)
    rooms = cur.fetchall()

    conn.close()

    return render_template(
        "rooms_status.html",
        rooms=rooms,
        unique_statuses=unique_statuses,
        unique_types=unique_types,
        unique_wings=unique_wings,
        status=status,
        room_type=room_type,
        wing=wing,
        search=search,
    )


@app.route("/rooms-status/update", methods=["POST"])
def update_room_status():
    room_number = request.form.get("room_number")
    new_status_name = request.form.get("new_status")

    if not room_number or not new_status_name:
        return redirect(url_for("rooms_status"))

    conn = get_db_connection()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()



    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # 1. Look up roomID from roomNumber
    cur.execute("SELECT roomID FROM room WHERE roomNumber = ?", (room_number,))
    room_row = cur.fetchone()
    if not room_row:
        conn.close()
        return redirect(url_for("rooms_status"))

    room_id = room_row["roomID"]

    # 2. Look up statusID from statusName
    cur.execute("SELECT statusID FROM room_status WHERE statusName = ?", (new_status_name,))
    status_row = cur.fetchone()
    if not status_row:
        conn.close()
        return redirect(url_for("rooms_status"))

    status_id = status_row["statusID"]

    # 3. Insert a new availability record with the current date
    cur.execute("""
    INSERT OR REPLACE INTO room_availability (roomID, statusID, timestamp)
    VALUES (?, ?, ?)
    """, (room_id, status_id, ts))

    conn.commit()
    conn.close()

    return redirect(url_for("rooms_status"))


@app.route("/dashboard")
def dashboard():
    conn = get_db_connection()
    cur = conn.cursor()

    # ---------- latest room status per room ----------
    latest_status_sql = """
        SELECT ra.roomID,
               r.roomNumber,
               s.statusName
        FROM room_availability ra
        JOIN (
            SELECT roomID, MAX(timestamp) AS max_ts
            FROM room_availability
            GROUP BY roomID
        ) latest
          ON ra.roomID = latest.roomID
         AND ra.timestamp = latest.max_ts
        JOIN room_status s ON ra.statusID = s.statusID
        JOIN room r ON r.roomID = ra.roomID
    """
    latest_status_rows = cur.execute(latest_status_sql).fetchall()

    total_rooms = len(latest_status_rows)
    occupied_rooms = [row for row in latest_status_rows if row["statusName"] == "Occupied"]
    reserved_rooms = [row for row in latest_status_rows if row["statusName"] == "Reserved"]
    available_rooms = [
        row for row in latest_status_rows
        if row["statusName"] in ("Available", "Ready for Check-in")
    ]
    out_of_service_rooms = [row for row in latest_status_rows if row["statusName"] == "Out of Service"]

    occupancy_percent = 0
    if total_rooms:
        occupancy_percent = round(len(occupied_rooms) / total_rooms * 100)

    def pct(count):
        return round(count / total_rooms * 100) if total_rooms else 0

    available_pct = pct(len(available_rooms))
    reserved_pct = pct(len(reserved_rooms))
    out_of_service_pct = pct(len(out_of_service_rooms))

    today_str = date.today().isoformat()

    # ---------- Today's check-ins ----------
    checkins_sql = """
        SELECT r.reservationID,
               c.name,
               r.startDate
        FROM reservation r
        JOIN customer c ON r.customerID = c.customerID
        WHERE r.startDate = ?
        ORDER BY r.startDate, c.name
    """
    checkins_today = cur.execute(checkins_sql, (today_str,)).fetchall()

    # ---------- Today's check-outs ----------
    checkouts_sql = """
        SELECT r.reservationID,
               c.name,
               r.checkOutDate
        FROM reservation r
        JOIN customer c ON r.customerID = c.customerID
        WHERE r.checkOutDate IS NOT NULL
          AND date(r.checkOutDate) = ?
        ORDER BY r.checkOutDate, c.name
    """
    checkouts_today = cur.execute(checkouts_sql, (today_str,)).fetchall()

    # total charged service per reservation (for the $ in the card)
    service_totals_sql = """
        SELECT reservationID,
               SUM(amount) AS total_amount
        FROM charged_service
        GROUP BY reservationID
    """
    service_totals = {
        row["reservationID"]: row["total_amount"]
        for row in cur.execute(service_totals_sql).fetchall()
    }

    checkouts_with_amounts = []
    for row in checkouts_today:
        rid = row["reservationID"]
        amount = service_totals.get(rid, 0.0) or 0.0
        checkouts_with_amounts.append({
            "name": row["name"],
            "checkOutDate": row["checkOutDate"],
            "amount": amount,
        })

    # ---------- Events today ----------
    event_sql = """
        SELECT e.eventID,
               e.estimatedStartDate,
               e.estimatedEndDate,
               e.estimatedAttendance,
               c.name AS customer_name
        FROM event e
        JOIN customer c ON e.customerID = c.customerID
        WHERE ? BETWEEN e.estimatedStartDate AND e.estimatedEndDate
        ORDER BY e.estimatedStartDate
    """
    events_today = cur.execute(event_sql, (today_str,)).fetchall()
    event_today = events_today[0] if events_today else None

    # ---------- Housekeeping & maintenance ----------
    cleaning_rooms = [row for row in latest_status_rows if row["statusName"] == "Being Cleaned"]
    ready_rooms = [
        row for row in latest_status_rows
        if row["statusName"] in ("Available", "Ready for Check-in")
    ]
    maintenance_rooms = [
        row for row in latest_status_rows
        if row["statusName"] in ("Under Maintenance", "Out of Service")
    ]

    conn.close()

    return render_template(
        "dashboard.html",
        occupancy_percent=occupancy_percent,
        total_rooms=total_rooms,
        occupied_count=len(occupied_rooms),
        reserved_count=len(reserved_rooms),
        available_count=len(available_rooms),
        out_of_service_count=len(out_of_service_rooms),
        available_pct=available_pct,
        reserved_pct=reserved_pct,
        out_of_service_pct=out_of_service_pct,
        checkins_today=checkins_today,
        checkouts_today=checkouts_with_amounts,
        events_today=events_today,
        event_today=event_today,
        cleaning_rooms=cleaning_rooms,
        ready_rooms=ready_rooms,
        maintenance_rooms=maintenance_rooms,
    )

@app.route("/reservation")
def reservation():
    conn = get_db_connection()
    cur = conn.cursor()

    status = request.args.get("status", "").strip()
    channel = request.args.get("channel", "").strip()
    search = request.args.get("search", "").strip()

    # Base query
    sql = """
        SELECT
            r.reservationID,
            r.startDate,
            r.endDate,
            r.checkOutDate,
            r.channel,
            r.status,
            c.name AS customerName,
            GROUP_CONCAT(DISTINCT rm.roomNumber) AS roomNumbers
        FROM reservation r
        JOIN customer c
          ON r.customerID = c.customerID
        LEFT JOIN room_assignment ra
          ON r.reservationID = ra.reservationID
        LEFT JOIN room rm
          ON ra.roomID = rm.roomID
        WHERE 1 = 1
    """

    params = []

    if status:
        sql += " AND r.status = ?"
        params.append(status)

    if channel:
        sql += " AND r.channel = ?"
        params.append(channel)

    if search:
        sql += " AND (c.name LIKE ? OR CAST(r.reservationID AS TEXT) LIKE ?)"
        like = f"%{search}%"
        params.extend([like, like])

    sql += """
        GROUP BY
            r.reservationID, r.startDate, r.endDate,
            r.checkOutDate, r.channel, r.status, c.name
        ORDER BY r.startDate DESC
    """

    reservations = cur.execute(sql, params).fetchall()

    # Distinct status and channel lists for filters
    unique_statuses = [
        row["status"]
        for row in cur.execute("SELECT DISTINCT status FROM reservation ORDER BY status").fetchall()
    ]
    unique_channels = [
        row["channel"]
        for row in cur.execute("SELECT DISTINCT channel FROM reservation ORDER BY channel").fetchall()
    ]

    conn.close()

    return render_template(
        "reservation.html",
        reservations=reservations,
        unique_statuses=unique_statuses,
        unique_channels=unique_channels,
        status=status,
        channel=channel,
        search=search,
    )

@app.route("/guests/add", methods=["POST"])
def add_guest():
    name = (request.form.get("name") or "").strip()
    email = (request.form.get("email") or "").strip()
    phone = (request.form.get("phone") or "").strip()
    gender = (request.form.get("gender") or "").strip() or None

    if not name:
        return redirect(url_for("guests"))

    conn = get_db_connection()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    # Create a new customerID (since your schema uses INT PK without AUTOINCREMENT)
    cur.execute("SELECT COALESCE(MAX(customerID), 0) + 1 AS next_id FROM customer")
    next_id = cur.fetchone()["next_id"]

    cur.execute(
        """
        INSERT INTO customer (customerID, name, phone, email, gender)
        VALUES (?, ?, ?, ?, ?)
        """,
        (next_id, name, phone, email, gender),
    )

    conn.commit()
    conn.close()

    return redirect(url_for("guests"))



@app.route("/guests")
def guests():
    search = (request.args.get("search") or "").strip()

    conn = get_db_connection()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    sql = """
        SELECT
            c.customerID,
            c.name,
            c.phone,
            c.email,
            c.gender,
            COUNT(r.reservationID) AS totalReservations,
            MAX(r.endDate)         AS lastEndDate
        FROM customer c
        LEFT JOIN reservation r
            ON c.customerID = r.customerID
        WHERE 1 = 1
    """
    params = []

    if search:
        sql += " AND (c.name LIKE ? OR c.email LIKE ?)"
        like = f"%{search}%"
        params.extend([like, like])

    sql += """
        GROUP BY c.customerID, c.name, c.phone, c.email, c.gender
        ORDER BY c.name COLLATE NOCASE
    """

    cur.execute(sql, params)
    guests = cur.fetchall()

    conn.close()

    return render_template("guests.html", guests=guests, search=search)




@app.route("/events")
def events():
    # filters from query string
    status = (request.args.get("status") or "").strip()
    room_needed = (request.args.get("room_needed") or "").strip()
    search = (request.args.get("search") or "").strip()

    conn = get_db_connection()
    cur = conn.cursor()

    # --- main events query ---
    sql = """
        SELECT
            e.eventID,
            e.roomNeeded,
            e.estimatedAttendance,
            e.estimatedStartDate,
            e.estimatedEndDate,
            e.billingParty,
            c.name         AS customerName,
            ct.description AS customerType,
            CASE
                WHEN e.estimatedStartDate > DATE('now') THEN 'Upcoming'
                WHEN e.estimatedEndDate   < DATE('now') THEN 'Completed'
                ELSE 'In Progress'
            END            AS eventStatus
        FROM event e
        JOIN customer c
          ON e.customerID = c.customerID
        JOIN customer_type ct
          ON e.customerTypeID = ct.customerTypeID
        WHERE 1 = 1
    """
    params = []

    # status filter
    if status == "upcoming":
        sql += " AND e.estimatedStartDate > DATE('now')"
    elif status == "completed":
        sql += " AND e.estimatedEndDate < DATE('now')"
    elif status == "in_progress":
        sql += " AND e.estimatedStartDate <= DATE('now') AND e.estimatedEndDate >= DATE('now')"

    # room-needed filter
    if room_needed == "yes":
        sql += " AND e.roomNeeded = 1"
    elif room_needed == "no":
        sql += " AND e.roomNeeded = 0"

    # search filter
    if search:
        sql += " AND (CAST(e.eventID AS TEXT) LIKE ? OR c.name LIKE ?)"
        like = f"%{search}%"
        params.extend([like, like])

    sql += " ORDER BY e.estimatedStartDate ASC, e.eventID ASC"

    cur.execute(sql, params)
    events = cur.fetchall()

    # --- dropdown data for the create-event form ---
    cur.execute("SELECT customerID, name FROM customer ORDER BY name")
    customers = cur.fetchall()

    cur.execute("SELECT customerTypeID, description FROM customer_type ORDER BY description")
    customer_types = cur.fetchall()

    conn.close()

    return render_template(
        "events.html",
        events=events,
        status=status,
        room_needed=room_needed,
        search=search,
        customers=customers,
        customer_types=customer_types,
    )


@app.route("/events/add", methods=["POST"])
def add_event():
    room_needed_raw = (request.form.get("roomNeeded") or "").lower()
    billing_raw = (request.form.get("billingParty") or "").lower()

    room_needed = 1 if room_needed_raw == "yes" else 0
    billing_party = 1 if billing_raw == "customer" else 0

    attendance = request.form.get("estimatedAttendance") or 0
    start_date = request.form.get("estimatedStartDate")
    end_date = request.form.get("estimatedEndDate")
    customer_id = request.form.get("customerID")
    customer_type_id = request.form.get("customerTypeID")

    # Simple guard: if anything critical is missing, just skip insert
    if not (start_date and end_date and customer_id and customer_type_id):
        return redirect(url_for("events"))

    conn = get_db_connection()
    cur = conn.cursor()

    # generate next eventID (because eventID is INT PK, not AUTOINCREMENT)
    cur.execute("SELECT COALESCE(MAX(eventID), 0) + 1 AS next_id FROM event")
    next_id = cur.fetchone()["next_id"]

    cur.execute(
        """
        INSERT INTO event (
            eventID,
            roomNeeded,
            estimatedAttendance,
            estimatedStartDate,
            estimatedEndDate,
            customerID,
            customerTypeID,
            billingParty
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            next_id,
            room_needed,
            int(attendance),
            start_date,
            end_date,
            int(customer_id),
            int(customer_type_id),
            billing_party,
        ),
    )

    conn.commit()
    conn.close()

    return redirect(url_for("events"))





@app.route("/billing")
@app.route("/billing/<int:billing_id>")
def billing(billing_id=None):
    conn = get_db_connection()
    cur = conn.cursor()

    # ----------------- search logic -----------------
    search_term = request.args.get("search", "").strip()

    if search_term:
        # If user types a number, treat it as invoice (billingID) first
        if search_term.isdigit():
            cur.execute(
                "SELECT billingID FROM billing WHERE billingID = ?",
                (int(search_term),),
            )
            row = cur.fetchone()
            if row:
                billing_id = row["billingID"]

        # Otherwise, try to match by guest name or room number
        if billing_id is None:
            cur.execute(
                """
                SELECT b.billingID
                FROM billing b
                JOIN customer c ON b.customerID = c.customerID
                LEFT JOIN reservation r ON b.reservationID = r.reservationID
                LEFT JOIN room_assignment ra ON ra.reservationID = r.reservationID
                LEFT JOIN room rm ON rm.roomID = ra.roomID
                WHERE c.name LIKE ? OR rm.roomNumber LIKE ?
                ORDER BY b.billingID DESC
                LIMIT 1;
                """,
                (f"%{search_term}%", f"%{search_term}%"),
            )
            row = cur.fetchone()
            if row:
                billing_id = row["billingID"]

    # If still no billing_id, just grab the most recent one
    if billing_id is None:
        cur.execute("SELECT billingID FROM billing ORDER BY billingID DESC LIMIT 1;")
        row = cur.fetchone()
        if not row:
            conn.close()
            return render_template(
                "billing.html", invoice=None, line_items=[], search=search_term
            )
        billing_id = row["billingID"]

    # 1) Basic invoice info
    cur.execute(
        """
        SELECT
            b.billingID,
            r.reservationID,
            c.name            AS guest_name,
            r.startDate,
            r.endDate,
            r.status          AS reservation_status,
            rm.roomNumber
        FROM billing b
        JOIN reservation r
          ON b.reservationID = r.reservationID
        JOIN customer c
          ON b.customerID = c.customerID
        LEFT JOIN room_assignment ra
          ON ra.reservationID = r.reservationID
        LEFT JOIN room rm
          ON rm.roomID = ra.roomID
        WHERE b.billingID = ?
        LIMIT 1;
        """,
        (billing_id,),
    )
    base = cur.fetchone()
    if not base:
        conn.close()
        return render_template(
            "billing.html", invoice=None, line_items=[], search=search_term
        )

    reservation_id = base["reservationID"]

    # 2) Room charges
    cur.execute(
        """
        SELECT
            COALESCE(
                SUM(rt.price * (julianday(r.endDate) - julianday(r.startDate))),
                0
            ) AS room_charges
        FROM billing b
        JOIN reservation r
          ON b.reservationID = r.reservationID
        LEFT JOIN room_assignment ra
          ON ra.reservationID = r.reservationID
        LEFT JOIN room rm
          ON rm.roomID = ra.roomID
        LEFT JOIN room_type rt
          ON rm.roomTypeID = rt.roomTypeID
        WHERE b.billingID = ?;
        """,
        (billing_id,),
    )
    room_charges_row = cur.fetchone()
    room_charges = room_charges_row["room_charges"] if room_charges_row else 0.0

    # 3) Service charges
    cur.execute(
        """
        SELECT
            COALESCE(SUM(cs.amount), 0) AS service_charges
        FROM billing b
        JOIN reservation r
          ON b.reservationID = r.reservationID
        LEFT JOIN charged_service cs
          ON cs.reservationID = r.reservationID
        WHERE b.billingID = ?;
        """,
        (billing_id,),
    )
    service_row = cur.fetchone()
    service_charges = service_row["service_charges"] if service_row else 0.0

    # 4) Taxes – example: 10% of (room + services)
    subtotal = (room_charges or 0) + (service_charges or 0)
    taxes = round(subtotal * 0.10, 2)
    total_due = round(subtotal + taxes, 2)

    # 5) Latest payment
    cur.execute(
        """
        SELECT p.method, p.date
        FROM payment p
        JOIN billing b
          ON p.billingID = b.billingID
        WHERE b.billingID = ?
        ORDER BY p.date DESC, p.paymentID DESC
        LIMIT 1;
        """,
        (billing_id,),
    )
    pay = cur.fetchone()

    invoice = {
        "billing_id": billing_id,
        "status": "closed"
        if base["reservation_status"] == "Checked Out"
        else "open",
        "guest_name": base["guest_name"],
        "room_number": base["roomNumber"] or "–",
        "reservation_id": reservation_id,
        "total_due": total_due,
        "room_charges": room_charges,
        "service_charges": service_charges,
        "taxes": taxes,
        "updated_by": "Emily Johnson",             # placeholder
        "updated_time": "8:40 PM",                 # placeholder
        "payment_method": (
            f"{pay['method']} on {pay['date']}" if pay else "No payment on file"
        ),
    }

    # ------------ Line items --------------

    line_items = []

    # Room line item
    cur.execute(
        """
        SELECT
            rt.sizeLabel AS room_label,
            rt.price     AS nightly_rate,
            r.startDate,
            r.endDate,
            rm.roomNumber
        FROM billing b
        JOIN reservation r
          ON b.reservationID = r.reservationID
        JOIN room_assignment ra
          ON ra.reservationID = r.reservationID
        JOIN room rm
          ON rm.roomID = ra.roomID
        JOIN room_type rt
          ON rm.roomTypeID = rt.roomTypeID
        WHERE b.billingID = ?
        LIMIT 1;
        """,
        (billing_id,),
    )
    room_line = cur.fetchone()
    if room_line:
        start_d = date.fromisoformat(room_line["startDate"])
        end_d = date.fromisoformat(room_line["endDate"])
        nights = max((end_d - start_d).days, 1)
        unit_price = float(room_line["nightly_rate"])
        amount = round(unit_price * nights, 2)

        line_items.append(
            {
                "description": room_line["room_label"],
                "note": f"Room {room_line['roomNumber']}",
                "category": "Room",
                "qty": nights,
                "unit_price": unit_price,
                "amount": amount,
                "date": room_line["startDate"],
            }
        )

    # Service line items
    cur.execute(
        """
        SELECT
            cs.chargedServiceId,
            cst.serviceDescription,
            cs.amount,
            cs.time       AS service_date,
            cs.customerID
        FROM billing b
        JOIN reservation r
          ON b.reservationID = r.reservationID
        JOIN charged_service cs
          ON cs.reservationID = r.reservationID
        JOIN charged_service_type cst
          ON cs.serviceTypeId = cst.serviceTypeId
        WHERE b.billingID = ?
        ORDER BY cs.time, cs.chargedServiceId;
        """,
        (billing_id,),
    )
    service_rows = cur.fetchall()

    for row in service_rows:
        unit_price = float(row["amount"])
        line_items.append(
            {
                "description": row["serviceDescription"],
                "note": f"Customer ID {row['customerID']}",
                "category": "Service",
                "qty": 1,
                "unit_price": unit_price,
                "amount": unit_price,
                "date": row["service_date"],
            }
        )

    conn.close()

    return render_template(
        "billing.html",
        invoice=invoice,
        line_items=line_items,
        search=search_term,
    )

@app.route("/queries")
def queries():
    conn = get_db_connection()
    cur = conn.cursor()

    # Query 1: Revenue trend analysis by month
    query1_sql = """
        SELECT 
            strftime('%Y-%m', r.startDate) AS month,
            COUNT(DISTINCT r.reservationID) AS reservation_count,
            COALESCE(SUM(CASE WHEN rt.price IS NOT NULL THEN rt.price * (julianday(r.endDate) - julianday(r.startDate)) ELSE 0 END), 0) AS room_revenue,
            COALESCE(SUM(cs.amount), 0) AS service_revenue,
            COALESCE(SUM(CASE WHEN rt.price IS NOT NULL THEN rt.price * (julianday(r.endDate) - julianday(r.startDate)) ELSE 0 END), 0) + 
            COALESCE(SUM(cs.amount), 0) AS total_revenue
        FROM reservation r
        LEFT JOIN room_assignment ra ON r.reservationID = ra.reservationID
        LEFT JOIN room rm ON ra.roomID = rm.roomID
        LEFT JOIN room_type rt ON rm.roomTypeID = rt.roomTypeID
        LEFT JOIN charged_service cs ON r.reservationID = cs.reservationID
        WHERE r.startDate IS NOT NULL
        GROUP BY strftime('%Y-%m', r.startDate)
        HAVING reservation_count > 0
        ORDER BY month DESC
        LIMIT 24
    """
    query1_results = cur.execute(query1_sql).fetchall()

    # Query 2: Service type usage and revenue analysis
    query2_sql = """
        SELECT 
            cst.serviceDescription AS service_type,
            cst.price AS base_price,
            COUNT(cs.chargedServiceId) AS usage_count,
            COUNT(DISTINCT cs.reservationID) AS reservations_using_service,
            COUNT(DISTINCT cs.customerID) AS unique_customers,
            COALESCE(SUM(cs.amount), 0) AS total_revenue,
            ROUND(AVG(cs.amount), 2) AS avg_amount_per_use,
            MIN(cs.time) AS first_used_date,
            MAX(cs.time) AS last_used_date
        FROM charged_service_type cst
        LEFT JOIN charged_service cs ON cst.serviceTypeId = cs.serviceTypeId
        GROUP BY cst.serviceTypeId, cst.serviceDescription, cst.price
        HAVING usage_count > 0
        ORDER BY total_revenue DESC
    """
    query2_results = cur.execute(query2_sql).fetchall()

    # Query 3: Top revenue customers
    query3_sql = """
        SELECT 
            c.customerID,
            c.name,
            COUNT(DISTINCT r.reservationID) AS reservation_count,
            COALESCE(SUM(CASE WHEN rt.price IS NOT NULL THEN rt.price * (julianday(r.endDate) - julianday(r.startDate)) ELSE 0 END), 0) AS room_revenue,
            COALESCE(SUM(cs.amount), 0) AS service_revenue,
            COALESCE(SUM(CASE WHEN rt.price IS NOT NULL THEN rt.price * (julianday(r.endDate) - julianday(r.startDate)) ELSE 0 END), 0) + 
            COALESCE(SUM(cs.amount), 0) AS total_revenue
        FROM customer c
        LEFT JOIN reservation r ON c.customerID = r.customerID
        LEFT JOIN room_assignment ra ON r.reservationID = ra.reservationID
        LEFT JOIN room rm ON ra.roomID = rm.roomID
        LEFT JOIN room_type rt ON rm.roomTypeID = rt.roomTypeID
        LEFT JOIN charged_service cs ON r.reservationID = cs.reservationID
        WHERE r.reservationID IS NOT NULL
        GROUP BY c.customerID, c.name
        HAVING total_revenue > 0
        ORDER BY total_revenue DESC
        LIMIT 10
    """
    query3_results = cur.execute(query3_sql).fetchall()

    # Query 4: Booking channel analysis
    query4_sql = """
        SELECT 
            r.channel,
            COUNT(DISTINCT r.reservationID) AS reservation_count,
            COUNT(DISTINCT r.customerID) AS unique_customers,
            COALESCE(SUM(CASE WHEN rt.price IS NOT NULL THEN rt.price * (julianday(r.endDate) - julianday(r.startDate)) ELSE 0 END), 0) AS total_revenue,
            ROUND(AVG(julianday(r.endDate) - julianday(r.startDate)), 2) AS avg_stay_days
        FROM reservation r
        LEFT JOIN room_assignment ra ON r.reservationID = ra.reservationID
        LEFT JOIN room rm ON ra.roomID = rm.roomID
        LEFT JOIN room_type rt ON rm.roomTypeID = rt.roomTypeID
        WHERE r.channel IS NOT NULL
        GROUP BY r.channel
        ORDER BY total_revenue DESC
    """
    query4_results = cur.execute(query4_sql).fetchall()

    # Query 5: Room type popularity
    query5_sql = """
        SELECT 
            rt.sizeLabel AS room_type,
            rt.price AS base_price,
            COUNT(DISTINCT r.reservationID) AS booking_count,
            COUNT(DISTINCT r.customerID) AS unique_customers,
            ROUND(AVG(CASE WHEN r.endDate IS NOT NULL AND r.startDate IS NOT NULL THEN julianday(r.endDate) - julianday(r.startDate) ELSE NULL END), 2) AS avg_stay_days,
            COALESCE(SUM(CASE WHEN r.endDate IS NOT NULL AND r.startDate IS NOT NULL THEN rt.price * (julianday(r.endDate) - julianday(r.startDate)) ELSE 0 END), 0) AS total_revenue
        FROM room_type rt
        LEFT JOIN room rm ON rt.roomTypeID = rm.roomTypeID
        LEFT JOIN room_assignment ra ON rm.roomID = ra.roomID
        LEFT JOIN reservation r ON ra.reservationID = r.reservationID
        GROUP BY rt.roomTypeID, rt.sizeLabel, rt.price
        ORDER BY booking_count DESC
    """
    query5_results = cur.execute(query5_sql).fetchall()

    # Query 6: Customer booking frequency
    query6_sql = """
        SELECT 
            c.customerID,
            c.name,
            COUNT(r.reservationID) AS total_reservations,
            MIN(r.startDate) AS first_booking,
            MAX(r.startDate) AS last_booking,
            ROUND(AVG(julianday(r.endDate) - julianday(r.startDate)), 2) AS avg_stay_days,
            SUM(CASE WHEN r.status = 'Checked Out' THEN 1 ELSE 0 END) AS completed_reservations
        FROM customer c
        LEFT JOIN reservation r ON c.customerID = r.customerID
        WHERE r.reservationID IS NOT NULL
        GROUP BY c.customerID, c.name
        HAVING total_reservations > 0
        ORDER BY total_reservations DESC
        LIMIT 15
    """
    query6_results = cur.execute(query6_sql).fetchall()

    # Query 7: Average stay duration by room type
    query7_sql = """
        SELECT 
            rt.sizeLabel AS room_type,
            COUNT(DISTINCT r.reservationID) AS reservation_count,
            ROUND(AVG(julianday(r.endDate) - julianday(r.startDate)), 2) AS avg_stay_days,
            MIN(julianday(r.endDate) - julianday(r.startDate)) AS min_stay_days,
            MAX(julianday(r.endDate) - julianday(r.startDate)) AS max_stay_days
        FROM room_type rt
        JOIN room rm ON rt.roomTypeID = rm.roomTypeID
        JOIN room_assignment ra ON rm.roomID = ra.roomID
        JOIN reservation r ON ra.reservationID = r.reservationID
        WHERE r.endDate IS NOT NULL AND r.startDate IS NOT NULL
        GROUP BY rt.roomTypeID, rt.sizeLabel
        ORDER BY avg_stay_days DESC
    """
    query7_results = cur.execute(query7_sql).fetchall()

    # Query 8: Monthly revenue comparison with service breakdown
    query8_sql = """
        SELECT 
            strftime('%Y-%m', r.startDate) AS month,
            COUNT(DISTINCT r.reservationID) AS reservation_count,
            COALESCE(SUM(CASE WHEN rt.price IS NOT NULL THEN rt.price * (julianday(r.endDate) - julianday(r.startDate)) ELSE 0 END), 0) AS room_revenue,
            COALESCE(SUM(cs.amount), 0) AS service_revenue,
            COUNT(DISTINCT cs.serviceTypeId) AS service_types_used,
            COALESCE(SUM(CASE WHEN rt.price IS NOT NULL THEN rt.price * (julianday(r.endDate) - julianday(r.startDate)) ELSE 0 END), 0) + 
            COALESCE(SUM(cs.amount), 0) AS total_revenue
        FROM reservation r
        LEFT JOIN room_assignment ra ON r.reservationID = ra.reservationID
        LEFT JOIN room rm ON ra.roomID = rm.roomID
        LEFT JOIN room_type rt ON rm.roomTypeID = rt.roomTypeID
        LEFT JOIN charged_service cs ON r.reservationID = cs.reservationID
        WHERE r.startDate IS NOT NULL
        GROUP BY strftime('%Y-%m', r.startDate)
        HAVING reservation_count > 0
        ORDER BY month DESC
        LIMIT 24
    """
    query8_results = cur.execute(query8_sql).fetchall()

    conn.close()

    return render_template(
        "queries.html",
        query1_results=query1_results,
        query2_results=query2_results,
        query3_results=query3_results,
        query4_results=query4_results,
        query5_results=query5_results,
        query6_results=query6_results,
        query7_results=query7_results,
        query8_results=query8_results,
    )

@app.route("/employee")
@app.route("/employee/<int:staff_id>")
def employee_profile(staff_id=None):
    conn = get_db_connection()
    cur = conn.cursor()

    # If no staff_id is given, pick the first staff member
    if staff_id is None:
        cur.execute("SELECT staffID FROM staff ORDER BY staffID LIMIT 1;")
        row = cur.fetchone()
        if not row:
            conn.close()
            return render_template("employee_profile.html", staff=None)
        staff_id = row["staffID"]

    # --- Basic staff info ---
    cur.execute(
        """
        SELECT staffID, name, gender, hireDate, department, phone
        FROM staff
        WHERE staffID = ?;
        """,
        (staff_id,),
    )
    staff = cur.fetchone()
    if not staff:
        conn.close()
        return render_template("employee_profile.html", staff=None)

    # --- Roles for this staff member ---
    cur.execute(
        """
        SELECT sr.roleType, sr.description
        FROM staff_assignment sa
        JOIN staff_role sr ON sa.roleID = sr.roleID
        WHERE sa.staffID = ?
        ORDER BY sr.roleType;
        """,
        (staff_id,),
    )
    roles = cur.fetchall()

    # --- Workload stats ---
    cur.execute(
        """
        SELECT COUNT(DISTINCT reservationID) AS total_reservations
        FROM staff_assignment
        WHERE staffID = ?;
        """,
        (staff_id,),
    )
    stats_row = cur.fetchone()
    total_reservations = stats_row["total_reservations"] if stats_row else 0

    cur.execute(
        """
        SELECT COUNT(*) AS total_actions
        FROM staff_log
        WHERE staffID = ?;
        """,
        (staff_id,),
    )
    actions_row = cur.fetchone()
    total_actions = actions_row["total_actions"] if actions_row else 0

    # --- Recent activity from staff_log ---
    cur.execute(
        """
        SELECT
            sl.time,
            sl.action,
            sl.reservationID,
            c.name AS customer_name
        FROM staff_log sl
        LEFT JOIN reservation r
          ON sl.reservationID = r.reservationID
        LEFT JOIN customer c
          ON r.customerID = c.customerID
        WHERE sl.staffID = ?
        ORDER BY sl.time DESC
        LIMIT 10;
        """,
        (staff_id,),
    )
    activity = cur.fetchall()

    conn.close()

    return render_template(
        "employee_profile.html",
        staff=staff,
        roles=roles,
        total_reservations=total_reservations,
        total_actions=total_actions,
        activity=activity, 
    )



if __name__ == "__main__":
    app.run(debug=True)
