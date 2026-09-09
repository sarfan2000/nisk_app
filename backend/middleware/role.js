module.exports = function (roles) {
    return function (req, res, next) {
        if (!req.user || !roles.includes(req.user.userType)) {
            return res.status(403).json({ msg: 'Access denied: insufficient permissions' });
        }
        next();
    };
};
