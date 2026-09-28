module.exports = function (roles) {
    return function (req, res, next) {
        if (!req.user) {
            return res.status(403).json({ msg: 'Access denied: no user context' });
        }
        
        // 1. Check primary userType
        if (roles.includes(req.user.userType)) {
            return next();
        }

        // 2. Check full roles array (if the token was signed with the roles array)
        if (req.user.roles && Array.isArray(req.user.roles)) {
            const hasRole = req.user.roles.some(r => roles.includes(r.role) && r.status === 'Active');
            if (hasRole) return next();
        }

        // Both primary and multi-roles failed
        return res.status(403).json({ msg: 'Access denied: insufficient permissions for ' + roles.join(',') });
    };
};
