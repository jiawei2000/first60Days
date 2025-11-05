const express = require('express')
const router = express.Router()
const WeeklyHeightWeightController = require('../controllers/weeklyHWController');


router.post('/:babyID', WeeklyHeightWeightController.newWeeklyHW);
router.get('/:babyID', WeeklyHeightWeightController.getWeeklyHWByBabyID);

module.exports = router