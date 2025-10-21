// middleware/auditMiddleware.js
const AuditService = require("../services/auditService");

// Remove undefined recursively; optionally redact sensitive fields
function sanitize(value, { redact = [] } = {}) {
  if (Array.isArray(value)) {
    const arr = value.map(v => sanitize(v, { redact })).filter(v => v !== undefined);
    return arr.length ? arr : undefined;
  }
  if (value && typeof value === "object" && !(value instanceof Date)) {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      if (redact.includes(k)) {
        out[k] = "[REDACTED]";
        continue;
      }
      const sv = sanitize(v, { redact });
      if (sv !== undefined) out[k] = sv;
    }
    return Object.keys(out).length ? out : undefined;
  }
  // Keep falsy primitives like 0/''/false, drop only undefined
  return value === undefined ? undefined : value;
}

function auditMiddleware(action) {
  return async (req, res, next) => {
    const start = Date.now();

    res.on("finish", async () => {
      let actor = "unknown";
      if (req.user?.id) {
        actor = `user:${req.user.id}`;
      } else if (req.originalUrl.startsWith("/login")) {
        actor = "unauthenticated";
      } else {
        actor = "system";
      }

      const status = res.statusCode >= 400 ? "FAILURE" : "SUCCESS";

      // Redact common sensitive fields; add more as needed
      const redactions = ["password", "confirmPassword", "token", "accessToken", "refreshToken", "authorization"];
      const cleanBody = sanitize(req.body, { redact: redactions });

      const details = {
        method: req.method,
        duration: Date.now() - start,
        ip: req.ip,
      };
      if (cleanBody !== undefined) details.body = cleanBody; // only attach if safe & non-empty

      await AuditService.log({
        actor,
        action,
        target: req.originalUrl,
        status,
        details
      });
    });

    next();
  };
}

module.exports = auditMiddleware;