const mongoose = require('mongoose');

const articleSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, unique: true },
    title: { type: String, required: true },
    content: { type: [String], required: true },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true },
);

module.exports =
  mongoose.models.Article || mongoose.model('Article', articleSchema);
