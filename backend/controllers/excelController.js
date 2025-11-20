const ExcelService = require('../services/excelService');

const excelController = {
     async exportUsers(req, res) {
        try {
            const { filename, mimeType, buffer } =
                await ExcelService.exportUsersToExcel();

            res.setHeader('Content-Type', mimeType);
            res.setHeader(
                'Content-Disposition',
                `attachment; filename="${filename}"`
            );
            res.setHeader('Content-Length', buffer.length);

            return res.status(200).send(buffer);
        } catch (err) {
            console.error('Failed to export users:', err);
            return res.status(500).json({
                message: 'Failed to generate export.',
            });
        }
    },
    async exportBabyJournal(req, res) {
        const { babyId } = req.params;
        try {
            const { filename, mimeType, buffer } =
                await ExcelService.exportJournalEntriesToExcel(babyId); 
            res.setHeader('Content-Type', mimeType);
            res.setHeader(
                'Content-Disposition',
                `attachment; filename="${filename}"`
            );
            res.setHeader('Content-Length', buffer.length);
            return res.status(200).send(buffer);
        } catch (err) {
            console.error('Failed to export baby journal:', err);
            return res.status(500).json({
                message: 'Failed to generate export.',
            });
        }
    },
    async importJournalEntriesFromExcel(req, res) {
        const { babyId } = req.params;
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded.' });
        }
        try {
            const importedCount =
                await ExcelService.importJournalEntriesFromExcel(
                    babyId,
                    req.file.buffer
                );
            return res.status(200).json({
                message: `Successfully imported ${importedCount} journal entries.`,
            });
        } catch (err) {
            console.error('Failed to import journal entries:', err);
            return res.status(500).json({
                message: 'Failed to import journal entries.',
            });
        }
    },
    async importFakeDataExcel(req, res) {
        const { babyId } = req.params;
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded.' });
        }
        try {
            const importedCount =
                await ExcelService.importFakeDataExcel(
                    babyId,
                    req.file.buffer
                );
            return res.status(200).json({
                message: `Successfully imported ${importedCount} journal entries.`,
            });
        } catch (err) {
            console.error('Failed to import journal entries:', err);
            return res.status(500).json({
                message: 'Failed to import journal entries.',
            });
        }
    },
}

module.exports = excelController;