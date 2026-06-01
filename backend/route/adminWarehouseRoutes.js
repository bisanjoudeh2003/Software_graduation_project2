// backend/route/adminWarehouseRoutes.js

const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const adminWarehouseController = require("../controller/adminWarehouseController");

function requireAdmin(req, res, next) {
  if (!req.user || req.user.role !== "admin") {
    return res.status(403).json({
      success: false,
      message: "Access denied. Admin only.",
    });
  }

  next();
}

router.use(authMiddleware);
router.use(requireAdmin);

/*
|--------------------------------------------------------------------------
| Admin warehouse overview
|--------------------------------------------------------------------------
*/

router.get("/overview", adminWarehouseController.getWarehouseOverview);

/*
|--------------------------------------------------------------------------
| Admin warehouse products
|--------------------------------------------------------------------------
*/

router.get("/products", adminWarehouseController.getProducts);

router.get("/products/:productId/details", adminWarehouseController.getProductDetails);

router.put("/products/:productId/approve", adminWarehouseController.approveProduct);

router.put(
  "/products/:productId/visibility",
  adminWarehouseController.updateProductVisibility
);

router.put("/products/:productId/flag", adminWarehouseController.flagProduct);

/*
|--------------------------------------------------------------------------
| Admin warehouse orders
|--------------------------------------------------------------------------
*/

router.get("/orders", adminWarehouseController.getOrders);

router.get("/orders/:orderId/details", adminWarehouseController.getOrderDetails);

router.put("/orders/:orderId/status", adminWarehouseController.updateOrderStatus);

/*
|--------------------------------------------------------------------------
| Admin warehouse owners
|--------------------------------------------------------------------------
*/

router.get("/owners", adminWarehouseController.getWarehouseOwners);

module.exports = router;