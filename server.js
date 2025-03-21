const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const session = require('express-session');
const app = express();
const port = process.env.PORT || 5000;

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/student_registration')
    .then(() => {
        console.log('Connected to MongoDB');
    })
    .catch(err => {
        console.error('MongoDB connection error:', err);
    });


// Define Schemas
const staffSchema = new mongoose.Schema({
    name: String,
    username: { type: String, unique: true },
    password: String
});

const principalSchema = new mongoose.Schema({
    username: { type: String, unique: true },
    password: String
});

const teamLeaderSchema = new mongoose.Schema({
    name: String,
    gender: String,
    ageUndertaken: Number,
    students: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Student' }]
});

const studentSchema = new mongoose.Schema({
    name: String,
    age: Number,
    gender: String,
    phone: String,
    address: String,
    teamLeader: { type: mongoose.Schema.Types.ObjectId, ref: 'TeamLeader' },
    registeredBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Staff' },
    registeredDate: { type: Date, default: Date.now }
});

// Create models
const Staff = mongoose.model('Staff', staffSchema);
const Principal = mongoose.model('Principal', principalSchema);
const TeamLeader = mongoose.model('TeamLeader', teamLeaderSchema);
const Student = mongoose.model('Student', studentSchema);

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
    secret: 'student-registration-secret',
    resave: false,
    saveUninitialized: true,
    cookie: { maxAge: 3600000 } // 1 hour
}));
app.set('view engine', 'ejs');

// Helper middleware
const isStaffAuthenticated = (req, res, next) => {
    if (req.session.userId && req.session.userType === 'staff') {
        return next();
    }
    return res.redirect('/?message=Please+login+first&messageType=warning');
};

const isPrincipalAuthenticated = (req, res, next) => {
    if (req.session.userId && req.session.userType === 'principal') {
        return next();
    }
    return res.redirect('/?message=Please+login+first&messageType=warning');
};

// Initialize default principal account
async function initializeDefaultPrincipal() {
    try {
        const principalCount = await Principal.countDocuments({});
        if (principalCount === 0) {
            const hashedPassword = await bcrypt.hash('admin123', 10);
            await Principal.create({
                username: 'admin',
                password: hashedPassword
            });
            console.log('Default principal account created');
        }
    } catch (error) {
        console.error('Error creating default principal:', error);
    }
}

// Routes
app.get('/', (req, res) => {
    res.render('index', { 
        message: req.query.message || '', 
        messageType: req.query.messageType || 'info' 
    });
});

// Staff routes
app.post('/staff/signup', async (req, res) => {
    try {
        const { name, username, password } = req.body;
        const existingStaff = await Staff.findOne({ username });
        
        if (existingStaff) {
            return res.redirect('/?message=Username+already+exists&messageType=danger');
        }
        
        const hashedPassword = await bcrypt.hash(password, 10);
        const newStaff = new Staff({
            name,
            username,
            password: hashedPassword
        });
        
        await newStaff.save();
        res.redirect('/?message=Account+created+successfully.+Please+login&messageType=success');
    } catch (error) {
        console.error('Staff signup error:', error);
        res.redirect('/?message=Error+creating+account&messageType=danger');
    }
});

app.post('/staff/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        const staff = await Staff.findOne({ username });
        
        if (!staff) {
            return res.redirect('/?message=Invalid+username+or+password&messageType=danger');
        }
        
        const isPasswordValid = await bcrypt.compare(password, staff.password);
        if (!isPasswordValid) {
            return res.redirect('/?message=Invalid+username+or+password&messageType=danger');
        }
        
        req.session.userId = staff._id;
        req.session.userType = 'staff';
        res.redirect('/staff/dashboard');
    } catch (error) {
        console.error('Staff login error:', error);
        res.redirect('/?message=Login+error&messageType=danger');
    }
});

app.get('/staff/dashboard', isStaffAuthenticated, async (req, res) => {
    try {
        const staff = await Staff.findById(req.session.userId);
        const counts = {
            students: await Student.countDocuments({}),
            teams: await TeamLeader.countDocuments({})
        };
        
        const recentStudents = await Student.find({})
            .sort({ registeredDate: -1 })
            .limit(5)
            .populate('teamLeader');
        
        res.render('main', {
            title: 'Staff Dashboard',
            user: staff,
            userType: 'staff',
            active: 'dashboard',
            counts,
            recentStudents,
            message: req.query.message || '',
            messageType: req.query.messageType || 'info'
        });
    } catch (error) {
        console.error('Dashboard error:', error);
        res.redirect('/?message=Error+loading+dashboard&messageType=danger');
    }
});

app.get('/staff/register-student', isStaffAuthenticated, async (req, res) => {
    try {
        const staff = await Staff.findById(req.session.userId);
        
        res.render('main', {
            title: 'Register Student',
            user: staff,
            userType: 'staff',
            active: 'registration',
            message: req.query.message || '',
            messageType: req.query.messageType || 'info'
        });
    } catch (error) {
        console.error('Register page error:', error);
        res.redirect('/staff/dashboard?message=Error+loading+page&messageType=danger');
    }
});

app.post('/staff/register-student', isStaffAuthenticated, async (req, res) => {
    try {
        const { name, age, gender, phone, address } = req.body;
        
        // Find suitable team leader based on age and gender
        const eligibleTeamLeaders = await TeamLeader.find({
            ageUndertaken: parseInt(age),
            gender: gender
        }).populate({
            path: 'students',
            select: '_id'
        });
        
        if (eligibleTeamLeaders.length === 0) {
            return res.redirect('/staff/register-student?message=No+suitable+team+leader+found+for+this+student&messageType=warning');
        }
        
        // Sort team leaders by number of students (ascending)
        eligibleTeamLeaders.sort((a, b) => a.students.length - b.students.length);
        
        // Assign to team leader with fewest students
        const assignedTeamLeader = eligibleTeamLeaders[0];
        
        // Create new student
        const newStudent = new Student({
            name,
            age: parseInt(age),
            gender,
            phone,
            address,
            teamLeader: assignedTeamLeader._id,
            registeredBy: req.session.userId
        });
        
        await newStudent.save();
        
        // Update team leader's student list
        assignedTeamLeader.students.push(newStudent._id);
        await assignedTeamLeader.save();
        
        res.redirect('/staff/register-student?message=Student+registered+successfully&messageType=success');
    } catch (error) {
        console.error('Student registration error:', error);
        res.redirect('/staff/register-student?message=Error+registering+student&messageType=danger');
    }
});

app.get('/staff/view-teams', isStaffAuthenticated, async (req, res) => {
    try {
        const staff = await Staff.findById(req.session.userId);
        const teams = await TeamLeader.find({}).populate('students');
        
        res.render('main', {
            title: 'View Teams',
            user: staff,
            userType: 'staff',
            active: 'teams',
            teams,
            message: req.query.message || '',
            messageType: req.query.messageType || 'info'
        });
    } catch (error) {
        console.error('View teams error:', error);
        res.redirect('/staff/dashboard?message=Error+loading+teams&messageType=danger');
    }
});

// Principal routes
app.post('/principal/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        const principal = await Principal.findOne({ username });
        
        if (!principal) {
            return res.redirect('/?message=Invalid+credentials&messageType=danger');
        }
        
        const isPasswordValid = await bcrypt.compare(password, principal.password);
        if (!isPasswordValid) {
            return res.redirect('/?message=Invalid+credentials&messageType=danger');
        }
        
        req.session.userId = principal._id;
        req.session.userType = 'principal';
        res.redirect('/principal/dashboard');
    } catch (error) {
        console.error('Principal login error:', error);
        res.redirect('/?message=Login+error&messageType=danger');
    }
});

app.get('/principal/dashboard', isPrincipalAuthenticated, async (req, res) => {
    try {
        const principal = await Principal.findById(req.session.userId);
        const teamLeaders = await TeamLeader.find({});
        
        // Prepare team leaders with student counts
        const teamLeadersWithCounts = await Promise.all(teamLeaders.map(async (leader) => {
            const studentCount = await Student.countDocuments({ teamLeader: leader._id });
            return {
                _id: leader._id,
                name: leader.name,
                gender: leader.gender,
                ageUndertaken: leader.ageUndertaken,
                studentCount
            };
        }));
        
        const counts = {
            teamLeaders: await TeamLeader.countDocuments({}),
            students: await Student.countDocuments({}),
            staff: await Staff.countDocuments({})
        };
        
        res.render('main', {
            title: 'Principal Dashboard',
            user: { username: principal.username },
            userType: 'principal',
            active: 'dashboard',
            teamLeaders: teamLeadersWithCounts,
            counts,
            message: req.query.message || '',
            messageType: req.query.messageType || 'info'
        });
    } catch (error) {
        console.error('Principal dashboard error:', error);
        res.redirect('/?message=Error+loading+dashboard&messageType=danger');
    }
});

app.get('/principal/create-team', isPrincipalAuthenticated, async (req, res) => {
    try {
        const principal = await Principal.findById(req.session.userId);
        
        res.render('main', {
            title: 'Create Team Leader',
            user: { username: principal.username },
            userType: 'principal',
            active: 'create-team',
            message: req.query.message || '',
            messageType: req.query.messageType || 'info'
        });
    } catch (error) {
        console.error('Create team page error:', error);
        res.redirect('/principal/dashboard?message=Error+loading+page&messageType=danger');
    }
});

app.post('/principal/create-team', isPrincipalAuthenticated, async (req, res) => {
    try {
        const { name, gender, ageUndertaken } = req.body;
        
        const newTeamLeader = new TeamLeader({
            name,
            gender,
            ageUndertaken: parseInt(ageUndertaken),
            students: []
        });
        
        await newTeamLeader.save();
        
        res.redirect('/principal/create-team?message=Team+leader+created+successfully&messageType=success');
    } catch (error) {
        console.error('Create team leader error:', error);
        res.redirect('/principal/create-team?message=Error+creating+team+leader&messageType=danger');
    }
});

app.get('/principal/view-teams', isPrincipalAuthenticated, async (req, res) => {
    try {
        const principal = await Principal.findById(req.session.userId);
        const teams = await TeamLeader.find({}).populate('students');
        
        res.render('main', {
            title: 'Manage Teams',
            user: { username: principal.username },
            userType: 'principal',
            active: 'teams',
            teams,
            message: req.query.message || '',
            messageType: req.query.messageType || 'info'
        });
    } catch (error) {
        console.error('View teams error:', error);
        res.redirect('/principal/dashboard?message=Error+loading+teams&messageType=danger');
    }
});

app.post('/principal/reassign-student', isPrincipalAuthenticated, async (req, res) => {
    try {
        const { studentId, newTeamId } = req.body;
        
        // Get student and team info
        const student = await Student.findById(studentId);
        const oldTeamId = student.teamLeader;
        
        // Update student's team leader
        student.teamLeader = newTeamId;
        await student.save();
        
        // Remove student from old team
        await TeamLeader.findByIdAndUpdate(oldTeamId, {
            $pull: { students: studentId }
        });
        
        // Add student to new team
        await TeamLeader.findByIdAndUpdate(newTeamId, {
            $push: { students: studentId }
        });
        
        res.redirect('/principal/view-teams?message=Student+reassigned+successfully&messageType=success');
    } catch (error) {
        console.error('Reassign student error:', error);
        res.redirect('/principal/view-teams?message=Error+reassigning+student&messageType=danger');
    }
});

app.get('/logout', (req, res) => {
    req.session.destroy();
    res.redirect('/?message=Logged+out+successfully&messageType=success');
});

// Initialize and start server
initializeDefaultPrincipal().then(() => {
    app.listen(port, () => {
        console.log(`Server running on port ${port}`);
    });
});