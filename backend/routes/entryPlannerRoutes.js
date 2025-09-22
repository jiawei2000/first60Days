const express = require("express");
const router = express.Router();
const EntryPlannerController = require("../controllers/entryPlannerController");
const { authenticateToken } = require('../config/authMiddleware');
// CRUD routes
router.post("/:babyId", EntryPlannerController.createPlanner);
router.get("/:babyId/:plannerId", EntryPlannerController.getPlanner);
router.put("/:babyId/:plannerId", EntryPlannerController.updatePlanner);
router.delete("/:babyId/:plannerId", EntryPlannerController.deletePlanner);

module.exports = router;
