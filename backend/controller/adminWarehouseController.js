// backend/controller/adminWarehouseController.js

const db = require("../config/db");
const notificationModel = require("../model/notificationModel");

function parseJsonValue(value) {
  if (!value) return null;

  if (typeof value === "object") return value;

  try {
    return JSON.parse(value);
  } catch (_) {
    return value;
  }
}

async function attachProductImages(products) {
  if (!Array.isArray(products) || products.length === 0) {
    return [];
  }

  const productIds = products.map((p) => p.id);

  const [images] = await db.query(
    `
    SELECT product_id, image_url
    FROM warehouse_product_images
    WHERE product_id IN (?)
    ORDER BY id ASC
    `,
    [productIds]
  );

  const imagesMap = {};

  for (const image of images) {
    if (!imagesMap[image.product_id]) {
      imagesMap[image.product_id] = [];
    }

    imagesMap[image.product_id].push(image.image_url);
  }

  return products.map((product) => ({
    ...product,
    custom_fields: parseJsonValue(product.custom_fields),
    images: imagesMap[product.id] || [],
  }));
}

function getOrderReceiverId(order) {
  return order.client_id || order.photographer_id || null;
}

exports.getWarehouseOverview = async (req, res) => {
  try {
    const [[productStats]] = await db.query(
      `
      SELECT
        COUNT(*) AS total_products,
        SUM(CASE WHEN product_reviewed = 0 THEN 1 ELSE 0 END) AS pending_products,
        SUM(CASE WHEN product_reviewed = 1 AND admin_visibility = 'visible' THEN 1 ELSE 0 END) AS approved_visible_products,
        SUM(CASE WHEN product_reviewed = 1 AND admin_visibility = 'hidden' THEN 1 ELSE 0 END) AS hidden_products,
        SUM(CASE WHEN product_flagged = 1 THEN 1 ELSE 0 END) AS flagged_products,
        SUM(CASE WHEN stock_quantity <= 0 AND product_type = 'ready' THEN 1 ELSE 0 END) AS out_of_stock_products
      FROM warehouse_products
      WHERE is_active = 1
      `
    );

    const [[orderStats]] = await db.query(
      `
      SELECT
        COUNT(*) AS total_orders,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending_orders,
        SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) AS approved_orders,
        SUM(CASE WHEN status = 'completed' OR status = 'delivered' THEN 1 ELSE 0 END) AS completed_orders,
        SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) AS rejected_orders,
        SUM(CASE WHEN status = 'cancelled' OR status = 'canceled' THEN 1 ELSE 0 END) AS cancelled_orders,
        SUM(CASE WHEN payment_status = 'paid' THEN 1 ELSE 0 END) AS paid_orders
      FROM warehouse_orders
      `
    );

    const [[ownerStats]] = await db.query(
      `
      SELECT COUNT(*) AS total_warehouse_owners
      FROM users
      WHERE role = 'warehouse_owner'
      `
    );

    res.json({
      success: true,
      stats: {
        total_products: Number(productStats.total_products || 0),
        pending_products: Number(productStats.pending_products || 0),
        approved_visible_products: Number(productStats.approved_visible_products || 0),
        hidden_products: Number(productStats.hidden_products || 0),
        flagged_products: Number(productStats.flagged_products || 0),
        out_of_stock_products: Number(productStats.out_of_stock_products || 0),

        total_orders: Number(orderStats.total_orders || 0),
        pending_orders: Number(orderStats.pending_orders || 0),
        approved_orders: Number(orderStats.approved_orders || 0),
        completed_orders: Number(orderStats.completed_orders || 0),
        rejected_orders: Number(orderStats.rejected_orders || 0),
        cancelled_orders: Number(orderStats.cancelled_orders || 0),
        paid_orders: Number(orderStats.paid_orders || 0),

        total_warehouse_owners: Number(ownerStats.total_warehouse_owners || 0),
      },
    });
  } catch (error) {
    console.error("Admin warehouse overview error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to load warehouse overview",
      error: error.message,
    });
  }
};

exports.getProducts = async (req, res) => {
  try {
    const { status, visibility, flagged, stock } = req.query;

    const conditions = ["p.is_active = 1"];
    const params = [];

    if (status === "pending") {
      conditions.push("p.product_reviewed = 0");
    }

    if (status === "approved") {
      conditions.push("p.product_reviewed = 1");
    }

    if (visibility === "visible") {
      conditions.push("p.admin_visibility = 'visible'");
    }

    if (visibility === "hidden") {
      conditions.push("p.admin_visibility = 'hidden'");
    }

    if (flagged === "1" || flagged === "true") {
      conditions.push("p.product_flagged = 1");
    }

    if (stock === "out") {
      conditions.push("p.product_type = 'ready'");
      conditions.push("p.stock_quantity <= 0");
    }

    const whereSql = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";

    const [productsRows] = await db.query(
  `
  SELECT
    p.*,

    CASE
      WHEN p.product_type = 'ready' AND p.stock_quantity <= 0 THEN 'out_of_stock'
      WHEN p.status = 'hidden' THEN 'hidden'
      ELSE 'available'
    END AS display_status,

    owner.id AS owner_id,
    owner.full_name AS owner_name,
    owner.email AS owner_email,
    owner.profile_image AS owner_image,

    reviewer.id AS reviewer_id,
    reviewer.full_name AS reviewer_name
  FROM warehouse_products p
  JOIN users owner ON p.warehouse_owner_id = owner.id
  LEFT JOIN users reviewer ON p.product_reviewed_by = reviewer.id
  ${whereSql}
  ORDER BY
    CASE WHEN p.product_reviewed = 0 THEN 0 ELSE 1 END,
    p.id DESC
  `,
  params
);

    const products = await attachProductImages(productsRows);

    res.json({
      success: true,
      products,
    });
  } catch (error) {
    console.error("Admin get warehouse products error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to load warehouse products",
      error: error.message,
    });
  }
};

exports.getProductDetails = async (req, res) => {
  try {
    const productId = req.params.productId;

    const [[productRow]] = await db.query(
      `
      SELECT
        p.id,
        p.warehouse_owner_id,
        p.store_id,
        p.name,
        p.category,
        p.product_type,
        p.preview_type,
        p.allow_preview,
        p.description,
        p.image_url,
        p.price,
        p.stock_quantity,
        p.allow_custom_text,
        p.allow_color_choice,
        p.allow_size_choice,
        p.allow_event_date,
        p.allow_reference_image,
        p.custom_fields,
        p.status,
        p.is_active,
        p.created_at,

        p.admin_visibility,
        p.product_reviewed,
        p.product_reviewed_at,
        p.product_reviewed_by,
        p.product_flagged,
        p.product_flag_reason,

        CASE
          WHEN p.product_type = 'ready' AND p.stock_quantity <= 0 THEN 'out_of_stock'
          WHEN p.status = 'hidden' THEN 'hidden'
          ELSE 'available'
        END AS display_status,

        owner.id AS owner_id,
        owner.full_name AS owner_name,
        owner.email AS owner_email,
        owner.profile_image AS owner_image,

        reviewer.id AS reviewer_id,
        reviewer.full_name AS reviewer_name

      FROM warehouse_products p
      JOIN users owner ON p.warehouse_owner_id = owner.id
      LEFT JOIN users reviewer ON p.product_reviewed_by = reviewer.id
      WHERE p.id = ?
      LIMIT 1
      `,
      [productId]
    );

    if (!productRow) {
      return res.status(404).json({
        success: false,
        message: "Product not found",
      });
    }

    const [images] = await db.query(
      `
      SELECT id, product_id, image_url
      FROM warehouse_product_images
      WHERE product_id = ?
      ORDER BY id ASC
      `,
      [productId]
    );

    const [[orderStats]] = await db.query(
      `
      SELECT
        COUNT(DISTINCT oi.order_id) AS orders_count,
        COALESCE(SUM(oi.quantity), 0) AS total_quantity_ordered,
        COALESCE(SUM(oi.total_price), 0) AS total_sales
      FROM warehouse_order_items oi
      WHERE oi.product_id = ?
      `,
      [productId]
    );

    res.json({
      success: true,
      product: {
        ...productRow,
        custom_fields: parseJsonValue(productRow.custom_fields),
        images: images.map((img) => img.image_url),
        order_stats: {
          orders_count: Number(orderStats.orders_count || 0),
          total_quantity_ordered: Number(orderStats.total_quantity_ordered || 0),
          total_sales: Number(orderStats.total_sales || 0),
        },
      },
    });
  } catch (error) {
    console.error("Admin get warehouse product details error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to load warehouse product details",
      error: error.message,
    });
  }
};

exports.approveProduct = async (req, res) => {
  try {
    const adminId = req.user.id;
    const productId = req.params.productId;

    const [[product]] = await db.query(
      `
      SELECT *
      FROM warehouse_products
      WHERE id = ?
      LIMIT 1
      `,
      [productId]
    );

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found",
      });
    }

    await db.query(
      `
      UPDATE warehouse_products
      SET
        product_reviewed = 1,
        product_reviewed_at = NOW(),
        product_reviewed_by = ?,
        admin_visibility = 'visible',
        product_flagged = 0,
        product_flag_reason = NULL
      WHERE id = ?
      `,
      [adminId, productId]
    );

    try {
      await notificationModel.createNotification(
        product.warehouse_owner_id,
        "Warehouse Product Approved",
        `Your product "${product.name}" has been approved and is now visible in the warehouse.`,
        "warehouse_product"
      );
    } catch (notificationError) {
      console.log("Approve warehouse product notification error:", notificationError.message);
    }

    res.json({
      success: true,
      message: "Product approved successfully",
    });
  } catch (error) {
    console.error("Admin approve warehouse product error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to approve product",
      error: error.message,
    });
  }
};

exports.updateProductVisibility = async (req, res) => {
  try {
    const adminId = req.user.id;
    const productId = req.params.productId;
    const { admin_visibility } = req.body;

    if (!["visible", "hidden"].includes(admin_visibility)) {
      return res.status(400).json({
        success: false,
        message: "Invalid visibility value",
      });
    }

    const [[product]] = await db.query(
      `
      SELECT *
      FROM warehouse_products
      WHERE id = ?
      LIMIT 1
      `,
      [productId]
    );

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found",
      });
    }

    await db.query(
      `
      UPDATE warehouse_products
      SET
        admin_visibility = ?,
        product_reviewed = 1,
        product_reviewed_at = COALESCE(product_reviewed_at, NOW()),
        product_reviewed_by = COALESCE(product_reviewed_by, ?)
      WHERE id = ?
      `,
      [admin_visibility, adminId, productId]
    );

    try {
      const title =
        admin_visibility === "visible"
          ? "Warehouse Product Visible"
          : "Warehouse Product Hidden";

      const message =
        admin_visibility === "visible"
          ? `Your product "${product.name}" is now visible in the warehouse.`
          : `Your product "${product.name}" has been hidden by admin.`;

      await notificationModel.createNotification(
        product.warehouse_owner_id,
        title,
        message,
        "warehouse_product"
      );
    } catch (notificationError) {
      console.log("Warehouse visibility notification error:", notificationError.message);
    }

    res.json({
      success: true,
      message:
        admin_visibility === "visible"
          ? "Product is now visible"
          : "Product is now hidden",
    });
  } catch (error) {
    console.error("Admin update warehouse product visibility error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to update product visibility",
      error: error.message,
    });
  }
};

exports.flagProduct = async (req, res) => {
  try {
    const productId = req.params.productId;
    const { product_flagged, product_flag_reason } = req.body;

    const flagged =
      product_flagged === true ||
      product_flagged === 1 ||
      product_flagged === "1" ||
      product_flagged === "true";

    const [[product]] = await db.query(
      `
      SELECT *
      FROM warehouse_products
      WHERE id = ?
      LIMIT 1
      `,
      [productId]
    );

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found",
      });
    }

    await db.query(
      `
      UPDATE warehouse_products
      SET
        product_flagged = ?,
        product_flag_reason = ?
      WHERE id = ?
      `,
      [flagged ? 1 : 0, flagged ? product_flag_reason || null : null, productId]
    );

    if (flagged) {
      try {
        await notificationModel.createNotification(
          product.warehouse_owner_id,
          "Warehouse Product Flagged",
          product_flag_reason && product_flag_reason.trim()
            ? `Your product "${product.name}" was flagged by admin. Reason: ${product_flag_reason}`
            : `Your product "${product.name}" was flagged by admin.`,
          "warehouse_product"
        );
      } catch (notificationError) {
        console.log("Flag warehouse product notification error:", notificationError.message);
      }
    }

    res.json({
      success: true,
      message: flagged ? "Product flagged successfully" : "Product flag removed successfully",
    });
  } catch (error) {
    console.error("Admin flag warehouse product error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to update product flag",
      error: error.message,
    });
  }
};

exports.getOrders = async (req, res) => {
  try {
    const { status, payment_status } = req.query;

    const conditions = [];
    const params = [];

    if (status) {
      conditions.push("wo.status = ?");
      params.push(status);
    }

    if (payment_status) {
      conditions.push("wo.payment_status = ?");
      params.push(payment_status);
    }

    const whereSql = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";

    const [ordersRows] = await db.query(
      `
      SELECT
        wo.*,

        warehouse_owner.id AS warehouse_owner_user_id,
        warehouse_owner.full_name AS warehouse_owner_name,
        warehouse_owner.email AS warehouse_owner_email,

        CASE
          WHEN wo.photographer_id IS NOT NULL THEN 'photographer'
          WHEN wo.client_id IS NOT NULL THEN 'client'
          ELSE 'unknown'
        END AS requester_role,

        CASE
          WHEN wo.photographer_id IS NOT NULL THEN photographer.id
          WHEN wo.client_id IS NOT NULL THEN client.id
          ELSE NULL
        END AS requester_user_id,

        CASE
          WHEN wo.photographer_id IS NOT NULL THEN photographer.full_name
          WHEN wo.client_id IS NOT NULL THEN client.full_name
          ELSE NULL
        END AS requester_name,

        CASE
          WHEN wo.photographer_id IS NOT NULL THEN photographer.email
          WHEN wo.client_id IS NOT NULL THEN client.email
          ELSE NULL
        END AS requester_email

      FROM warehouse_orders wo
      JOIN users warehouse_owner ON wo.warehouse_owner_id = warehouse_owner.id
      LEFT JOIN users client ON wo.client_id = client.id
      LEFT JOIN users photographer ON wo.photographer_id = photographer.id
      ${whereSql}
      ORDER BY wo.id DESC
      `,
      params
    );

    if (ordersRows.length === 0) {
      return res.json({
        success: true,
        orders: [],
      });
    }

    const orderIds = ordersRows.map((order) => order.id);

    const [itemsRows] = await db.query(
      `
      SELECT
        oi.*,
        p.name AS product_name,
        p.category,
        p.image_url,
        p.product_type
      FROM warehouse_order_items oi
      JOIN warehouse_products p ON oi.product_id = p.id
      WHERE oi.order_id IN (?)
      ORDER BY oi.id ASC
      `,
      [orderIds]
    );

    const itemsMap = {};

    for (const item of itemsRows) {
      if (!itemsMap[item.order_id]) {
        itemsMap[item.order_id] = [];
      }

      itemsMap[item.order_id].push({
        ...item,
        custom_details: parseJsonValue(item.custom_details),
      });
    }

    const orders = ordersRows.map((order) => ({
      ...order,
      items: itemsMap[order.id] || [],
    }));

    res.json({
      success: true,
      orders,
    });
  } catch (error) {
    console.error("Admin get warehouse orders error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to load warehouse orders",
      error: error.message,
    });
  }
};

exports.getOrderDetails = async (req, res) => {
  try {
    const orderId = req.params.orderId;

    const [[order]] = await db.query(
      `
      SELECT
        wo.*,

        warehouse_owner.id AS warehouse_owner_user_id,
        warehouse_owner.full_name AS warehouse_owner_name,
        warehouse_owner.email AS warehouse_owner_email,

        CASE
          WHEN wo.photographer_id IS NOT NULL THEN 'photographer'
          WHEN wo.client_id IS NOT NULL THEN 'client'
          ELSE 'unknown'
        END AS requester_role,

        CASE
          WHEN wo.photographer_id IS NOT NULL THEN photographer.id
          WHEN wo.client_id IS NOT NULL THEN client.id
          ELSE NULL
        END AS requester_user_id,

        CASE
          WHEN wo.photographer_id IS NOT NULL THEN photographer.full_name
          WHEN wo.client_id IS NOT NULL THEN client.full_name
          ELSE NULL
        END AS requester_name,

        CASE
          WHEN wo.photographer_id IS NOT NULL THEN photographer.email
          WHEN wo.client_id IS NOT NULL THEN client.email
          ELSE NULL
        END AS requester_email

      FROM warehouse_orders wo
      JOIN users warehouse_owner ON wo.warehouse_owner_id = warehouse_owner.id
      LEFT JOIN users client ON wo.client_id = client.id
      LEFT JOIN users photographer ON wo.photographer_id = photographer.id
      WHERE wo.id = ?
      LIMIT 1
      `,
      [orderId]
    );

    if (!order) {
      return res.status(404).json({
        success: false,
        message: "Order not found",
      });
    }

    const [items] = await db.query(
      `
      SELECT
        oi.*,
        p.name AS product_name,
        p.category,
        p.image_url,
        p.product_type,
        p.preview_type
      FROM warehouse_order_items oi
      JOIN warehouse_products p ON oi.product_id = p.id
      WHERE oi.order_id = ?
      ORDER BY oi.id ASC
      `,
      [orderId]
    );

    res.json({
      success: true,
      order: {
        ...order,
        items: items.map((item) => ({
          ...item,
          custom_details: parseJsonValue(item.custom_details),
        })),
      },
    });
  } catch (error) {
    console.error("Admin get warehouse order details error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to load warehouse order details",
      error: error.message,
    });
  }
};

exports.updateOrderStatus = async (req, res) => {
  try {
    const orderId = req.params.orderId;
    const { status, admin_note } = req.body;

    const allowedStatuses = [
      "pending",
      "approved",
      "rejected",
      "completed",
      "cancelled",
      "canceled",
      "delivered",
    ];

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid order status",
      });
    }

    const [[order]] = await db.query(
      `
      SELECT *
      FROM warehouse_orders
      WHERE id = ?
      LIMIT 1
      `,
      [orderId]
    );

    if (!order) {
      return res.status(404).json({
        success: false,
        message: "Order not found",
      });
    }

    await db.query(
      `
      UPDATE warehouse_orders
      SET
        status = ?,
        owner_response = COALESCE(?, owner_response)
      WHERE id = ?
      `,
      [status, admin_note || null, orderId]
    );

    const receiverId = getOrderReceiverId(order);

    if (receiverId) {
      try {
        await notificationModel.createNotification(
          receiverId,
          "Warehouse Order Updated by Admin",
          admin_note && admin_note.trim()
            ? `Your warehouse order #${orderId} was updated to ${status}. Note: ${admin_note}`
            : `Your warehouse order #${orderId} was updated to ${status}.`,
          "warehouse_order"
        );
      } catch (notificationError) {
        console.log("Admin warehouse order notification error:", notificationError.message);
      }
    }

    try {
      await notificationModel.createNotification(
        order.warehouse_owner_id,
        "Warehouse Order Updated by Admin",
        admin_note && admin_note.trim()
          ? `Order #${orderId} was updated to ${status}. Note: ${admin_note}`
          : `Order #${orderId} was updated to ${status}.`,
        "warehouse_order"
      );
    } catch (notificationError) {
      console.log("Admin warehouse owner order notification error:", notificationError.message);
    }

    res.json({
      success: true,
      message: "Order status updated successfully",
    });
  } catch (error) {
    console.error("Admin update warehouse order status error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to update order status",
      error: error.message,
    });
  }
};

exports.getWarehouseOwners = async (req, res) => {
  try {
    const [owners] = await db.query(
      `
      SELECT
        u.id,
        u.full_name,
        u.email,
        u.profile_image,
        u.created_at,

        COALESCE(product_stats.products_count, 0) AS products_count,
        COALESCE(product_stats.pending_products_count, 0) AS pending_products_count,
        COALESCE(product_stats.flagged_products_count, 0) AS flagged_products_count,

        COALESCE(order_stats.orders_count, 0) AS orders_count,
        COALESCE(order_stats.paid_orders_count, 0) AS paid_orders_count

      FROM users u

      LEFT JOIN (
        SELECT
          warehouse_owner_id,
          COUNT(id) AS products_count,
          SUM(CASE WHEN product_reviewed = 0 THEN 1 ELSE 0 END) AS pending_products_count,
          SUM(CASE WHEN product_flagged = 1 THEN 1 ELSE 0 END) AS flagged_products_count
        FROM warehouse_products
        WHERE is_active = 1
        GROUP BY warehouse_owner_id
      ) product_stats
        ON product_stats.warehouse_owner_id = u.id

      LEFT JOIN (
        SELECT
          warehouse_owner_id,
          COUNT(id) AS orders_count,
          SUM(
            CASE
              WHEN LOWER(TRIM(payment_status)) = 'paid' THEN 1
              ELSE 0
            END
          ) AS paid_orders_count
        FROM warehouse_orders
        GROUP BY warehouse_owner_id
      ) order_stats
        ON order_stats.warehouse_owner_id = u.id

      WHERE u.role = 'warehouse_owner'
      ORDER BY u.id DESC
      `
    );

    res.json({
      success: true,
      owners: owners.map((owner) => ({
        ...owner,
        products_count: Number(owner.products_count || 0),
        pending_products_count: Number(owner.pending_products_count || 0),
        flagged_products_count: Number(owner.flagged_products_count || 0),
        orders_count: Number(owner.orders_count || 0),
        paid_orders_count: Number(owner.paid_orders_count || 0),
      })),
    });
  } catch (error) {
    console.error("Admin get warehouse owners error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to load warehouse owners",
      error: error.message,
    });
  }
};