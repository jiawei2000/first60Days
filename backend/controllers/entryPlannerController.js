const EntryPlannerService = require("../services/entryPlannerService");

class EntryPlannerController {
    static async createPlanner(req, res) {
        try {
            //firstfeed, last feed 
            const { babyId } = req.params;
            const plannerData = req.body;
            const planner = await EntryPlannerService.createPlanner(babyId, plannerData);

            return res.status(201).json({
                message: "Entry Planner created successfully",
                planner
            });
        } catch (error) {
            console.error("Error creating Entry Planner:", error);
            return res.status(500).json({ error: "Failed to create Entry Planner" });
        }
    }

    static async getPlanner(req, res) {
        try {
            const { babyId, plannerId } = req.params;
            const planner = await EntryPlannerService.getPlanner(plannerId);

            if (!planner) return res.status(404).json({ error: "Planner not found" });

            return res.status(200).json({ planner });
        } catch (error) {
            console.error("Error fetching Entry Planner:", error);
            return res.status(500).json({ error: "Failed to fetch Entry Planner" });
        }
    }

    static async updatePlanner(req, res) {
        try {
            const { babyId, plannerId } = req.params;
            const updateData = req.body;
            const updatedPlanner = await EntryPlannerService.updatePlanner(plannerId, updateData);

            return res.status(200).json({
                message: "Entry Planner updated successfully",
                planner: updatedPlanner
            });
        } catch (error) {
            console.error("Error updating Entry Planner:", error);
            return res.status(500).json({ error: "Failed to update Entry Planner" });
        }
    }

    static async deletePlanner(req, res) {
        try {
            const { babyId, plannerId } = req.params;
            await EntryPlannerService.deletePlanner(plannerId);

            return res.status(200).json({ message: "Entry Planner deleted successfully" });
        } catch (error) {
            console.error("Error deleting Entry Planner:", error);
            return res.status(500).json({ error: "Failed to delete Entry Planner" });
        }
    }
}

module.exports = EntryPlannerController;
