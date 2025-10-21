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
        console.log("Authenticated user:", user);
        next();
    });
}

// Call after authenticateToken to check roles
function authorizeRoles(...allowed) {
  return (req, res, next) => {
    if (process.env.SKIP_AUTH === 'true') {
      // Skip role checks in testing if auth is skipped
      return next();
    }

    // Support single role string or array of roles in the JWT payload
    const userRole = req.user.role;
    console.log(userRole);
    const permitted = allowed.includes(userRole);
    if (!permitted) {
      return res.status(403).json({
        error: 'Insufficient role',
        required: allowed,
        actual: userRole,
      });
    }

    next();
  };
}

module.exports = { authenticateToken, authorizeRoles, JWT_SECRET };