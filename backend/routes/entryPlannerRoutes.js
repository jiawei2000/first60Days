const express = require("express");
const router = express.Router();
const EntryPlannerController = require("../controllers/entryPlannerController");
const { authenticateToken } = require('../config/authMiddleware');
// CRUD routes
router.post("/:babyId", authenticateToken, EntryPlannerController.createPlanner);
router.get("/:babyId/:plannerId", authenticateToken, EntryPlannerController.getPlanner);
router.put("/:babyId/:plannerId", authenticateToken, EntryPlannerController.updatePlanner);
router.delete("/:babyId/:plannerId", authenticateToken, EntryPlannerController.deletePlanner);

module.exports = router;
