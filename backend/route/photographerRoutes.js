const express = require("express");
const router = express.Router();

const photographerController = require("../controller/photographerController");
const authMiddleware = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");


// بروفايلي أنا
router.get(
 "/me",
 authMiddleware,
 photographerController.getMyProfile
);




// إنشاء بروفايل
router.post(
 "/",
 authMiddleware,
 roleMiddleware(["photographer"]),
 photographerController.createPhotographer
);


// تعديل بروفايل
router.put(
 "/me",
 authMiddleware,
 roleMiddleware(["photographer"]),
 photographerController.updatePhotographer
);



router.get(
  "/:id",
  authMiddleware,
  photographerController.getPhotographerById
); 


module.exports = router;