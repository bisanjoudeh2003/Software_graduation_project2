const express = require("express");
const router = express.Router();

const adminCommunityController = require("../controller/adminCommunityController");
const authMiddleware = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

router.use(authMiddleware);
router.use(roleMiddleware(["admin"]));

router.get("/posts", adminCommunityController.getAdminCommunityPosts);

router.get(
  "/posts/:postId/details",
  adminCommunityController.getAdminCommunityPostDetails
);

router.put(
  "/posts/:postId/approve",
  adminCommunityController.approveCommunityPost
);

router.put(
  "/posts/:postId/reject",
  adminCommunityController.rejectCommunityPost
);

router.put(
  "/posts/:postId/visibility",
  adminCommunityController.updateCommunityPostVisibility
);

router.put(
  "/comments/:commentId/hide",
  adminCommunityController.hideCommunityComment
);

module.exports = router;