const mongoose = require('mongoose');

const FinancialSettingSchema = new mongoose.Schema({
    workerBaseSalary: { type: Number, default: 0 },
    supervisorBaseSalary: { type: Number, default: 0 },
    officeStaffSalary: { type: Number, default: 0 },
    monthlyTargetRevenue: { type: Number, default: 500000 },
    incentivePercentage: { type: Number, default: 5 }, // 5%
    fixedOperatingCosts: { type: Number, default: 0 },
    variableCostsPerJob: { type: Number, default: 0 },
    lastUpdated: { type: Date, default: Date.now }
});

module.exports = mongoose.model('FinancialSetting', FinancialSettingSchema);
