// services/ExportService.js
const UserService = require('./userService.js');
const ExcelBuilder = require('../utils/excelBuilder.js');

class ExcelService {
  static async exportUsersToExcel() {
    // 1. Fetch domain objects
    const users = await UserService.getAllUsers();

    // 2. Convert models -> plain rows that ExcelBuilder understands
    const rows = users.map(u => ({
      Name: u.name ?? u.fullName ?? '',
      Email: u.email ?? '',
      PhoneNo: u.phoneNo ?? '',
      Relation: u.relation ?? '',
    }));

    // 3. Build workbook
    const buffer = await ExcelBuilder.buildWorkbookBuffer({
      sheetName: 'Users',
      rows,
      columnsConfig: {
        Name: { width: 25 },
        Email: { width: 30 },
        PhoneNo: { width: 15 },
        Relation: { width: 25 },
      },
    });

    return {
        filename: `users_export_${new Date()
        .toISOString()
        .split('T')[0]}.xlsx`,
      mimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      buffer,
    };
  }
}

module.exports = ExcelService;