const express = require("express");
const router = express.Router();

const adminVenueController = require("../controller/adminVenueController");
const authMiddleware = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

router.get(
  "/",
  authMiddleware,
  roleMiddleware(["admin"]),
  adminVenueController.getAdminVenues
);

router.get(
  "/:venueId/details",
  authMiddleware,
  roleMiddleware(["admin"]),
  adminVenueController.getAdminVenueDetails
);

router.put(
  "/:venueId/visibility",
  authMiddleware,
  roleMiddleware(["admin"]),
  adminVenueController.updateVenueVisibility
);

router.put(
  "/:venueId/reviewed",
  authMiddleware,
  roleMiddleware(["admin"]),
  adminVenueController.updateVenueReviewed
);

router.put(
  "/:venueId/flag",
  authMiddleware,
  roleMiddleware(["admin"]),
  adminVenueController.updateVenueFlag
);

module.exports = router;