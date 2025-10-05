// middleware/auditMiddleware.js
const AuditService = require("../services/auditService");

function auditMiddleware(action) {
  return async (req, res, next) => {
    const start = Date.now();

    res.on("finish", async () => {
      let actor = "unknown";

      if (req.user?.id) {
        actor = `user:${req.user.id}`;
      } else if (req.originalUrl.startsWith("/login")) {
        actor = "unauthenticated"; // login attempt
      } else {
        actor = "system"; // cron jobs, internal calls, etc.
      }

      const status = res.statusCode >= 400 ? "FAILURE" : "SUCCESS";

      await AuditService.log({
        actor,
        action,
        target: req.originalUrl,
        status,
        details: {
          method: req.method,
          duration: Date.now() - start,
          ip: req.ip,
          body: req.body
        }
      });
    });

    next();
  };
}

module.exports = auditMiddleware;