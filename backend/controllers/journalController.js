const JournalService = require('../services/journalService');

const journalController = {
    async createEntry(req, res) {
        try {
            const { babyId, ...entryData } = req.body;

            if (!babyId) {
                return res.status(400).json({ error: "babyId is required" });
            }

            const entry = await JournalService.createEntry(babyId, entryData);

            return res.status(201).json({
                message: "Journal entry created successfully",
                entry
            });
        } catch (error) {
            console.error("Error creating journal entry:", error);
            return res.status(500).json({ error: "Internal Server Error" });
        }
    },

    async editEntry(req, res) {
        try {
            const { babyId, entryId } = req.params;
            const updateData = req.body;

            if (!babyId || !entryId) {
                return res.status(400).json({ error: "babyId and entryId are required" });
            }

            const updatedEntry = await JournalService.editEntry(babyId, entryId, updateData);

            return res.status(200).json({
                message: "Journal entry updated successfully",
                entry: updatedEntry
            });

        } catch (error) {
            console.error("Error updating journal entry:", error);
            return res.status(500).json({ error: error.message });
        }
    },

    async getEntries(req, res) {
        try {
            const { babyId } = req.params;
            const entries = await JournalService.getEntries(babyId);

            if (entries.length === 0) {
                return res.status(404).json({ message: "No journal entries found" });
            }

            return res.status(200).json(entries);
        } catch (error) {
            console.error("Error getting journal entries:", error);
            return res.status(500).json({ error: "Internal Server Error" });
        }
    },

    async getEntryById(req, res) {
        try {
            const { babyId, entryId } = req.params;
            
            // Fetch journal entry from service
            const entry = await JournalService.getEntryById(babyId, entryId);

            if (!entry) {
                return res.status(404).json({ message: "No journal entry found" });
            }

            // Return formatted journal entry
            res.status(200).json(entry);

        } catch (error) {
            console.error("Error getting journal entry:", error);
            res.status(500).json({ error: "Internal Server Error" });
        }
    },
}

module.exports = journalController;