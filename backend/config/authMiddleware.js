const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'no_jwt_in_env';

function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (process.env.SKIP_AUTH === "true") {
        console.log("Auth skipped in testing mode");
        return next();
    }

    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid token' });
        }
        req.user = user;
        next();
    });
}

module.exports = authenticateToken;
