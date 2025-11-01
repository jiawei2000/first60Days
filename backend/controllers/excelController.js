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
}

module.exports = excelController;