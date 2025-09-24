const express = require("express");
const router = express.Router();
const EntryPlannerController = require("../controllers/entryPlannerController");
const { authenticateToken } = require('../config/authMiddleware');
// CRUD routes
router.post("/:babyId", EntryPlannerController.createPlanner);
router.get("/:babyId/:plannerId", EntryPlannerController.getPlanner);
router.get("/:babyId/", EntryPlannerController.getPlanners);
router.put("/:babyId/:plannerId", EntryPlannerController.updatePlanner);
router.put("/feedTimings/:babyId/:plannerId", EntryPlannerController.updateFeedTimings);
router.delete("/:babyId/:plannerId", EntryPlannerController.deletePlanner);

module.exports = router;
