const express = require("express");
const router = express.Router();
const EntryPlannerController = require("../controllers/entryPlannerController");
const { authenticateToken } = require('../middleware/authMiddleware');
// CRUD routes
router.post("/:babyId", authenticateToken, EntryPlannerController.createPlanner);

router.get("/:babyId/:plannerId", authenticateToken, EntryPlannerController.getPlanner);
router.get("/:babyId/", authenticateToken, EntryPlannerController.getPlanners);
router.put("/:babyId/:plannerId", authenticateToken, EntryPlannerController.updatePlanner);
router.put("/feedTimings/:babyId/:plannerId", authenticateToken, EntryPlannerController.updateFeedTimings);
router.delete("/:babyId/:plannerId", authenticateToken, EntryPlannerController.deletePlanner);

module.exports = router;
