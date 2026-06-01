const pool = require("../config/db");

const buildDateCondition = (dateFilter, dateColumn) => {
  if (dateFilter === "today") {
    return ` AND ${dateColumn} = CURDATE() `;
  }

  if (dateFilter === "upcoming") {
    return ` AND ${dateColumn} >= CURDATE() `;
  }

  if (dateFilter === "past") {
    return ` AND ${dateColumn} < CURDATE() `;
  }

  return "";
};

exports.getPhotographerBookings = async (req, res) => {
  try {
    const {
      status = "all",
      dateFilter = "all",
      search = "",
    } = req.query;

    const params = [];
    let where = " WHERE 1 = 1 ";

    if (status !== "all") {
      where += " AND pb.status = ? ";
      params.push(status);
    }

    where += buildDateCondition(dateFilter, "pb.date");

    if (search.trim()) {
      where += `
        AND (
          client.full_name LIKE ?
          OR photographerUser.full_name LIKE ?
          OR pb.session_type LIKE ?
          OR pb.location LIKE ?
          OR v.name LIKE ?
        )
      `;

      const q = `%${search.trim()}%`;
      params.push(q, q, q, q, q);
    }

    const [rows] = await pool.query(
      `
      SELECT
        pb.id,
        pb.client_id,
        pb.photographer_id,
        pb.venue_id,

        pb.session_type,
        pb.date,
        pb.time,
        pb.duration_hours,
        pb.location,
        pb.total_price,
        pb.deposit_amount,
        pb.remaining_amount,

        pb.deposit_paid,
        pb.deposit_paid_at,
        pb.remaining_paid,
        pb.remaining_paid_at,
        pb.remaining_payment_status,

        pb.status,
        pb.rejection_reason,
        pb.cancellation_reason,
        pb.cancelled_at,

        pb.refunded,
        pb.refunded_at,
        pb.refund_reason,

        pb.created_at,
        pb.updated_at,

        client.full_name AS client_name,
        client.email AS client_email,
        client.profile_image AS client_image,

        photographerUser.full_name AS photographer_name,
        photographerUser.email AS photographer_email,
        photographerUser.profile_image AS photographer_image,

        v.name AS venue_name,
        v.location AS venue_location

      FROM photographer_bookings pb

      JOIN users client
        ON client.id = pb.client_id

      JOIN photographers p
        ON p.photographer_id = pb.photographer_id

      JOIN users photographerUser
        ON photographerUser.id = p.user_id

      LEFT JOIN venues v
        ON v.id = pb.venue_id

      ${where}

      ORDER BY pb.created_at DESC
      LIMIT 200
      `,
      params
    );

    res.json({
      success: true,
      bookings: rows,
    });
  } catch (error) {
    console.error("Admin get photographer bookings error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to load photographer bookings",
      error: error.message,
    });
  }
};

exports.getVenueBookings = async (req, res) => {
  try {
    const {
      status = "all",
      dateFilter = "all",
      search = "",
    } = req.query;

    const params = [];
    let where = " WHERE 1 = 1 ";

    if (status !== "all") {
      where += " AND vb.status = ? ";
      params.push(status);
    }

    where += buildDateCondition(dateFilter, "vb.booking_date");

    if (search.trim()) {
      where += `
        AND (
          client.full_name LIKE ?
          OR owner.full_name LIKE ?
          OR v.name LIKE ?
          OR v.location LIKE ?
        )
      `;

      const q = `%${search.trim()}%`;
      params.push(q, q, q, q);
    }

    const [rows] = await pool.query(
      `
      SELECT
        vb.id,
        vb.client_id,
        vb.venue_id,
        vb.availability_id,

        vb.booking_date,
        vb.start_time,
        vb.end_time,
        vb.status,
        vb.total_price,
        vb.notes,

        vb.deposit_amount,
        vb.deposit_paid,
        vb.remaining_paid,

        vb.created_at,

        client.full_name AS client_name,
        client.email AS client_email,
        client.profile_image AS client_image,

        v.name AS venue_name,
        v.location AS venue_location,
        v.image_url AS venue_image,
        v.price_per_hour,

        owner.id AS owner_user_id,
        owner.full_name AS owner_name,
        owner.email AS owner_email,
        owner.profile_image AS owner_image

      FROM venue_bookings vb

      JOIN users client
        ON client.id = vb.client_id

      JOIN venues v
        ON v.id = vb.venue_id

      JOIN users owner
        ON owner.id = v.owner_id

      ${where}

      ORDER BY vb.created_at DESC
      LIMIT 200
      `,
      params
    );

    res.json({
      success: true,
      bookings: rows,
    });
  } catch (error) {
    console.error("Admin get venue bookings error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to load venue bookings",
      error: error.message,
    });
  }
};