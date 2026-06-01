const express = require("express");
const router = express.Router();

const adminPostSessionController = require("../controller/adminPostSessionController");
const authMiddleware = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

router.get(
  "/",
  authMiddleware,
  roleMiddleware(["admin"]),
  adminPostSessionController.getPostSessionMonitor
);

module.exports = router;