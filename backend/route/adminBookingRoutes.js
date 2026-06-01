const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");
const adminBookingController = require("../controller/adminBookingController");

router.use(authMiddleware);
router.use(roleMiddleware(["admin"]));

/*
|--------------------------------------------------------------------------
| Admin Bookings Management
|--------------------------------------------------------------------------
| Photographer bookings + Venue bookings
|--------------------------------------------------------------------------
*/

router.get(
  "/photographer",
  adminBookingController.getPhotographerBookings
);

router.get(
  "/venues",
  adminBookingController.getVenueBookings
);

module.exports = router;