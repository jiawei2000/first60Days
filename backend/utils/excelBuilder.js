const ExcelJS = require('exceljs');

class ExcelBuilder {
  static async buildWorkbookBuffer({ sheetName, rows, columnsConfig = {} }) {
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet(sheetName);

    if (!rows || rows.length === 0) {
      // Create an empty sheet with a note
      worksheet.addRow(['No data available']);
      return workbook.xlsx.writeBuffer();
    }

    // Infer columns from first row keys in order
    const firstRow = rows[0];

    const columns = Object.keys(firstRow).map(key => ({
      header: columnsConfig[key]?.header ?? key,
      key,
      width: columnsConfig[key]?.width ?? Math.max(key.length + 2, 15),
      style: columnsConfig[key]?.style ?? {},
    }));

    worksheet.columns = columns;

    // Add all rows
    worksheet.addRows(rows);

    // Optional: make header bold
    worksheet.getRow(1).font = { bold: true };

    // Return workbook as Buffer
    const buffer = await workbook.xlsx.writeBuffer();
    return Buffer.from(buffer);
  }
}

module.exports = ExcelBuilder;