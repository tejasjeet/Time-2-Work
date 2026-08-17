function validate(schema) {
  return (req, res, next) => {
    const parsed = schema.parse({
      body: req.body,
      query: req.query,
      params: req.params,
    });
    if (parsed.body) req.body = parsed.body;
    if (parsed.query) req.query = { ...req.query, ...parsed.query };
    if (parsed.params) req.params = parsed.params;
    next();
  };
}

function validateBody(schema) {
  return (req, res, next) => {
    req.body = schema.parse(req.body);
    next();
  };
}

function validateQuery(schema) {
  return (req, res, next) => {
    const parsed = schema.parse(req.query);
    req.query = { ...req.query, ...parsed };
    next();
  };
}

module.exports = { validate, validateBody, validateQuery };
