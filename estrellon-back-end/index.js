require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const connectDB = require('./config/db');
const admin = require('./config/firebaseAdmin');
const userRoutes = require('./routes/userRoutes');
const articleRoutes = require('./routes/articleRoutes');
const User = require('./models/User');

const app = express();
const jsonParser = bodyParser.json();

connectDB();

console.log(`Firebase Admin initialized: ${admin.app().options.projectId}`);

app.use(express.json());
app.use(jsonParser);
app.use(bodyParser.urlencoded({ extended: true }));

const corsOptions = {
  origin: '*',
  credentials: true,
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE'],
};

app.use(cors(corsOptions));
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Credentials', 'true');
  res.header(
    'Access-Control-Allow-Headers',
    'Origin, X-Requested-With, Content-Type, Accept, Authorization',
  );
  res.header(
    'Access-Control-Allow-Methods',
    'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  );
  next();
});

app.use('/api/users', userRoutes);
app.use('/api/articles', articleRoutes);

const seedDefaultUser = async () => {
  const count = await User.countDocuments();
  if (count > 0) return;

  const hashedPassword = await bcrypt.hash('12345', 10);

  await User.create({
    firstName: 'FirstName',
    lastName: 'LastName',
    age: '12',
    gender: 'Male',
    contactNumber: '09559409739',
    email: 'fname@example.com',
    username: 'fName',
    password: hashedPassword,
    address: 'Address',
    isActive: true,
    type: 'admin',
  });

  console.log('Default user seeded');
};

seedDefaultUser().catch((error) => {
  console.error(`Seed error: ${error.message}`);
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Server Error' });
});

const PORT = process.env.PORT || 5000;

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});

server.on('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} is already in use. Stop the other server first:`);
    console.error(`  netstat -ano | findstr :${PORT}`);
    console.error(`  taskkill /PID <PID> /F`);
    process.exit(1);
  }

  throw error;
});
