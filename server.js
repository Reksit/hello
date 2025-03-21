// Firebase setup and configuration
const express = require('express');
const session = require('express-session');
const bcrypt = require('bcrypt');
const ExcelJS = require('exceljs');
const app = express();
const port = process.env.PORT || 5000;

// Firebase setup
const { initializeApp } = require('firebase/app');
const { 
  getFirestore, 
  collection, 
  doc, 
  getDoc, 
  getDocs, 
  setDoc, 
  addDoc, 
  updateDoc, 
  query, 
  where, 
  orderBy, 
  limit,
  arrayUnion,
  arrayRemove,
  serverTimestamp 
} = require('firebase/firestore'); // Changed from firebase/database to firebase/firestore

// Your Firebase configuration
const firebaseConfig = {
    apiKey: "AIzaSyAvhjpYIL2tHwr5NWddwp-uslLQQPYSHp0",
    authDomain: "register2-2b2f1.firebaseapp.com",
    projectId: "register2-2b2f1",
    storageBucket: "register2-2b2f1.firebasestorage.app",
    messagingSenderId: "204113627122",
    appId: "1:204113627122:web:7dbdaa7290971cd8494d6b",
    measurementId: "G-YDV7T8Y7SE"
  };

// Initialize Firebase
const firebaseApp = initializeApp(firebaseConfig);
const db = getFirestore(firebaseApp);

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
        // Check if principal account exists
        const principalsRef = collection(db, 'principals');
        const principalsSnapshot = await getDocs(principalsRef);
        
        if (principalsSnapshot.empty) {
            const hashedPassword = await bcrypt.hash('admin123', 10);
            await addDoc(principalsRef, {
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
        
        // Check if username already exists
        const staffRef = collection(db, 'staff');
        const q = query(staffRef, where('username', '==', username));
        const staffSnapshot = await getDocs(q);
        
        if (!staffSnapshot.empty) {
            return res.redirect('/?message=Username+already+exists&messageType=danger');
        }
        
        const hashedPassword = await bcrypt.hash(password, 10);
        
        // Add new staff
        const newStaffRef = await addDoc(staffRef, {
            name,
            username,
            password: hashedPassword
        });
        
        res.redirect('/?message=Account+created+successfully.+Please+login&messageType=success');
    } catch (error) {
        console.error('Staff signup error:', error);
        res.redirect('/?message=Error+creating+account&messageType=danger');
    }
});

app.post('/staff/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        
        // Find staff with username
        const staffRef = collection(db, 'staff');
        const q = query(staffRef, where('username', '==', username));
        const staffSnapshot = await getDocs(q);
        
        if (staffSnapshot.empty) {
            return res.redirect('/?message=Invalid+username+or+password&messageType=danger');
        }
        
        // Get first matching staff
        const staffDoc = staffSnapshot.docs[0];
        const staffData = staffDoc.data();
        
        // Verify password
        const isPasswordValid = await bcrypt.compare(password, staffData.password);
        if (!isPasswordValid) {
            return res.redirect('/?message=Invalid+username+or+password&messageType=danger');
        }
        
        req.session.userId = staffDoc.id;
        req.session.userType = 'staff';
        res.redirect('/staff/dashboard');
    } catch (error) {
        console.error('Staff login error:', error);
        res.redirect('/?message=Login+error&messageType=danger');
    }
});

app.get('/staff/dashboard', isStaffAuthenticated, async (req, res) => {
    try {
        // Get staff data
        const staffRef = doc(db, 'staff', req.session.userId);
        const staffDoc = await getDoc(staffRef);
        
        if (!staffDoc.exists()) {
            throw new Error('Staff not found');
        }
        
        const staff = staffDoc.data();
        
        // Count students and teams
        const studentsRef = collection(db, 'students');
        const studentsSnapshot = await getDocs(studentsRef);
        const studentsCount = studentsSnapshot.size;
        
        const teamsRef = collection(db, 'teamLeaders');
        const teamsSnapshot = await getDocs(teamsRef);
        const teamsCount = teamsSnapshot.size;
        
        // Get recent students
        const recentStudentsQ = query(
            studentsRef,
            orderBy('registeredDate', 'desc'),
            limit(5)
        );
        const recentStudentsSnapshot = await getDocs(recentStudentsQ);
        
        // Format recent students with team leader data
        const recentStudents = [];
        for (const docSnap of recentStudentsSnapshot.docs) {
            const studentData = docSnap.data();
            let teamLeaderData = null;
            
            if (studentData.teamLeader) {
                const teamLeaderRef = doc(db, 'teamLeaders', studentData.teamLeader);
                const teamLeaderDoc = await getDoc(teamLeaderRef);
                if (teamLeaderDoc.exists()) {
                    teamLeaderData = teamLeaderDoc.data();
                }
            }
            
            recentStudents.push({
                id: docSnap.id,
                ...studentData,
                teamLeader: teamLeaderData
            });
        }
        
        res.render('main', {
            title: 'Staff Dashboard',
            user: { ...staff, id: req.session.userId },
            userType: 'staff',
            active: 'dashboard',
            counts: {
                students: studentsCount,
                teams: teamsCount
            },
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
        const staffRef = doc(db, 'staff', req.session.userId);
        const staffDoc = await getDoc(staffRef);
        
        if (!staffDoc.exists()) {
            throw new Error('Staff not found');
        }
        
        const staff = staffDoc.data();
        
        res.render('main', {
            title: 'Register Student',
            user: { ...staff, id: req.session.userId },
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
        const ageNum = parseInt(age);
        
        // Find suitable team leader based on age and gender
        const teamLeadersRef = collection(db, 'teamLeaders');
        const q = query(
            teamLeadersRef,
            where('ageUndertaken', '==', ageNum),
            where('gender', '==', gender)
        );
        const teamLeadersSnapshot = await getDocs(q);
        
        if (teamLeadersSnapshot.empty) {
            return res.redirect('/staff/register-student?message=No+suitable+team+leader+found+for+this+student&messageType=warning');
        }
        
        // Get all team leaders with student counts
        const teamLeaders = [];
        for (const docSnap of teamLeadersSnapshot.docs) {
            const teamLeaderData = docSnap.data();
            const studentCount = teamLeaderData.students ? teamLeaderData.students.length : 0;
            
            teamLeaders.push({
                id: docSnap.id,
                ...teamLeaderData,
                studentCount
            });
        }
        
        // Sort team leaders by number of students (ascending)
        teamLeaders.sort((a, b) => a.studentCount - b.studentCount);
        
        // Assign to team leader with fewest students
        const assignedTeamLeader = teamLeaders[0];
        
        // Create new student
        const studentsRef = collection(db, 'students');
        const newStudentRef = await addDoc(studentsRef, {
            name,
            age: ageNum,
            gender,
            phone,
            address,
            teamLeader: assignedTeamLeader.id,
            registeredBy: req.session.userId,
            registeredDate: serverTimestamp()
        });
        
        // Update team leader's student list
        const teamLeaderRef = doc(db, 'teamLeaders', assignedTeamLeader.id);
        await updateDoc(teamLeaderRef, {
            students: arrayUnion(newStudentRef.id)
        });
        
        res.redirect('/staff/register-student?message=Student+registered+successfully&messageType=success');
    } catch (error) {
        console.error('Student registration error:', error);
        res.redirect('/staff/register-student?message=Error+registering+student&messageType=danger');
    }
});

app.get('/staff/view-teams', isStaffAuthenticated, async (req, res) => {
    try {
        const staffRef = doc(db, 'staff', req.session.userId);
        const staffDoc = await getDoc(staffRef);
        
        if (!staffDoc.exists()) {
            throw new Error('Staff not found');
        }
        
        const staff = staffDoc.data();
        
        // Get all team leaders
        const teamLeadersRef = collection(db, 'teamLeaders');
        const teamLeadersSnapshot = await getDocs(teamLeadersRef);
        
        // Format teams with student data
        const teams = [];
        for (const docSnap of teamLeadersSnapshot.docs) {
            const teamLeaderData = docSnap.data();
            const studentList = [];
            
            // Get students for this team
            if (teamLeaderData.students && teamLeaderData.students.length > 0) {
                for (const studentId of teamLeaderData.students) {
                    const studentRef = doc(db, 'students', studentId);
                    const studentDoc = await getDoc(studentRef);
                    
                    if (studentDoc.exists()) {
                        studentList.push({
                            id: studentDoc.id,
                            ...studentDoc.data()
                        });
                    }
                }
            }
            
            teams.push({
                id: docSnap.id,
                ...teamLeaderData,
                students: studentList
            });
        }
        
        res.render('main', {
            title: 'View Teams',
            user: { ...staff, id: req.session.userId },
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
        
        // Find principal with username
        const principalsRef = collection(db, 'principals');
        const q = query(principalsRef, where('username', '==', username));
        const principalsSnapshot = await getDocs(q);
        
        if (principalsSnapshot.empty) {
            return res.redirect('/?message=Invalid+credentials&messageType=danger');
        }
        
        // Get first matching principal
        const principalDoc = principalsSnapshot.docs[0];
        const principalData = principalDoc.data();
        
        // Verify password
        const isPasswordValid = await bcrypt.compare(password, principalData.password);
        if (!isPasswordValid) {
            return res.redirect('/?message=Invalid+credentials&messageType=danger');
        }
        
        req.session.userId = principalDoc.id;
        req.session.userType = 'principal';
        res.redirect('/principal/dashboard');
    } catch (error) {
        console.error('Principal login error:', error);
        res.redirect('/?message=Login+error&messageType=danger');
    }
});

app.get('/principal/dashboard', isPrincipalAuthenticated, async (req, res) => {
    try {
        const principalRef = doc(db, 'principals', req.session.userId);
        const principalDoc = await getDoc(principalRef);
        
        if (!principalDoc.exists()) {
            throw new Error('Principal not found');
        }
        
        const principal = principalDoc.data();
        
        // Get all team leaders
        const teamLeadersRef = collection(db, 'teamLeaders');
        const teamLeadersSnapshot = await getDocs(teamLeadersRef);
        
        // Format team leaders with student counts
        const teamLeadersWithCounts = [];
        for (const docSnap of teamLeadersSnapshot.docs) {
            const teamLeaderData = docSnap.data();
            const studentCount = teamLeaderData.students ? teamLeaderData.students.length : 0;
            
            teamLeadersWithCounts.push({
                _id: docSnap.id,
                name: teamLeaderData.name,
                gender: teamLeaderData.gender,
                ageUndertaken: teamLeaderData.ageUndertaken,
                studentCount
            });
        }
        
        // Get counts
        const studentsRef = collection(db, 'students');
        const studentsSnapshot = await getDocs(studentsRef);
        
        const staffRef = collection(db, 'staff');
        const staffSnapshot = await getDocs(staffRef);
        
        const counts = {
            teamLeaders: teamLeadersSnapshot.size,
            students: studentsSnapshot.size,
            staff: staffSnapshot.size
        };
        
        res.render('main', {
            title: 'Principal Dashboard',
            user: { username: principal.username, id: req.session.userId },
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
        const principalRef = doc(db, 'principals', req.session.userId);
        const principalDoc = await getDoc(principalRef);
        
        if (!principalDoc.exists()) {
            throw new Error('Principal not found');
        }
        
        const principal = principalDoc.data();
        
        res.render('main', {
            title: 'Create Team Leader',
            user: { username: principal.username, id: req.session.userId },
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
        
        // Create new team leader
        const teamLeadersRef = collection(db, 'teamLeaders');
        await addDoc(teamLeadersRef, {
            name,
            gender,
            ageUndertaken: parseInt(ageUndertaken),
            students: []
        });
        
        res.redirect('/principal/create-team?message=Team+leader+created+successfully&messageType=success');
    } catch (error) {
        console.error('Create team leader error:', error);
        res.redirect('/principal/create-team?message=Error+creating+team+leader&messageType=danger');
    }
});

app.get('/principal/view-teams', isPrincipalAuthenticated, async (req, res) => {
    try {
        const principalRef = doc(db, 'principals', req.session.userId);
        const principalDoc = await getDoc(principalRef);
        
        if (!principalDoc.exists()) {
            throw new Error('Principal not found');
        }
        
        const principal = principalDoc.data();
        
        // Get all team leaders
        const teamLeadersRef = collection(db, 'teamLeaders');
        const teamLeadersSnapshot = await getDocs(teamLeadersRef);
        
        // Format teams with student data
        const teams = [];
        for (const docSnap of teamLeadersSnapshot.docs) {
            const teamLeaderData = docSnap.data();
            const studentList = [];
            
            // Get students for this team
            if (teamLeaderData.students && teamLeaderData.students.length > 0) {
                for (const studentId of teamLeaderData.students) {
                    const studentRef = doc(db, 'students', studentId);
                    const studentDoc = await getDoc(studentRef);
                    
                    if (studentDoc.exists()) {
                        studentList.push({
                            id: studentDoc.id,
                            ...studentDoc.data()
                        });
                    }
                }
            }
            
            teams.push({
                id: docSnap.id,
                ...teamLeaderData,
                students: studentList
            });
        }
        
        res.render('main', {
            title: 'Manage Teams',
            user: { username: principal.username, id: req.session.userId },
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
        
        // Get student
        const studentRef = doc(db, 'students', studentId);
        const studentDoc = await getDoc(studentRef);
        
        if (!studentDoc.exists()) {
            throw new Error('Student not found');
        }
        
        const student = studentDoc.data();
        const oldTeamId = student.teamLeader;
        
        // Update student's team leader
        await updateDoc(studentRef, {
            teamLeader: newTeamId
        });
        
        // Remove student from old team
        const oldTeamRef = doc(db, 'teamLeaders', oldTeamId);
        await updateDoc(oldTeamRef, {
            students: arrayRemove(studentId)
        });
        
        // Add student to new team
        const newTeamRef = doc(db, 'teamLeaders', newTeamId);
        await updateDoc(newTeamRef, {
            students: arrayUnion(studentId)
        });
        
        res.redirect('/principal/view-teams?message=Student+reassigned+successfully&messageType=success');
    } catch (error) {
        console.error('Reassign student error:', error);
        res.redirect('/principal/view-teams?message=Error+reassigning+student&messageType=danger');
    }
});

// Export students data route
app.get('/export-students', isPrincipalAuthenticated, async (req, res) => {
    try {
        // Fetch all students
        const studentsRef = collection(db, 'students');
        const studentsSnapshot = await getDocs(studentsRef);
        
        // Create a new Excel workbook and worksheet
        const workbook = new ExcelJS.Workbook();
        const worksheet = workbook.addWorksheet('Students');
        
        // Define columns
        worksheet.columns = [
            { header: 'Name', key: 'name', width: 30 },
            { header: 'Age', key: 'age', width: 10 },
            { header: 'Gender', key: 'gender', width: 15 },
            { header: 'Phone', key: 'phone', width: 20 },
            { header: 'Address', key: 'address', width: 40 },
            { header: 'Team Leader', key: 'teamLeader', width: 30 }
        ];
        
        // Add data rows
        for (const docSnap of studentsSnapshot.docs) {
            const studentData = docSnap.data();
            let teamLeaderName = 'Not Assigned';
            
            // Get team leader name
            if (studentData.teamLeader) {
                const teamLeaderRef = doc(db, 'teamLeaders', studentData.teamLeader);
                const teamLeaderDoc = await getDoc(teamLeaderRef);
                
                if (teamLeaderDoc.exists()) {
                    teamLeaderName = teamLeaderDoc.data().name;
                }
            }
            
            worksheet.addRow({
                name: studentData.name,
                age: studentData.age,
                gender: studentData.gender,
                phone: studentData.phone,
                address: studentData.address,
                teamLeader: teamLeaderName
            });
        }
        
        // Set response headers
        res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        res.setHeader('Content-Disposition', 'attachment; filename=students.xlsx');
        
        // Write to response
        await workbook.xlsx.write(res);
        res.end();
        
    } catch (error) {
        console.error('Error exporting students data:', error);
        res.redirect('/principal/dashboard?message=Failed+to+export+students+data&messageType=danger');
    }
});

// Export teams data route
app.get('/export-teams', isPrincipalAuthenticated, async (req, res) => {
    try {
        // Fetch all team leaders
        const teamLeadersRef = collection(db, 'teamLeaders');
        const teamLeadersSnapshot = await getDocs(teamLeadersRef);
        
        // Create a new Excel workbook and worksheet
        const workbook = new ExcelJS.Workbook();
        const worksheet = workbook.addWorksheet('Teams');
        
        // Define columns for teams overview
        worksheet.columns = [
            { header: 'Team Leader Name', key: 'name', width: 30 },
            { header: 'Age Group', key: 'ageUndertaken', width: 15 },
            { header: 'Gender', key: 'gender', width: 15 },
            { header: 'Total Students', key: 'studentCount', width: 20 }
        ];
        
        // Prepare teams data
        const teams = [];
        for (const docSnap of teamLeadersSnapshot.docs) {
            const teamLeaderData = docSnap.data();
            const studentCount = teamLeaderData.students ? teamLeaderData.students.length : 0;
            
            teams.push({
                id: docSnap.id,
                ...teamLeaderData,
                studentCount
            });
        }
        
        // Sort teams by age
        teams.sort((a, b) => a.ageUndertaken - b.ageUndertaken);
        
        // Add team data rows
        teams.forEach(team => {
            worksheet.addRow({
                name: team.name,
                ageUndertaken: team.ageUndertaken,
                gender: team.gender,
                studentCount: team.studentCount
            });
        });
        
        // Add separator row
        worksheet.addRow({});
        worksheet.addRow({ name: 'Detailed Team Information' });
        worksheet.addRow({});
        
        // For each team, add detailed student information
        for (const team of teams) {
            // Add team header
            worksheet.addRow({ name: `Team: ${team.name} - Age: ${team.ageUndertaken} - Gender: ${team.gender}` });
            
            // Add student headers if the team has students
            if (team.students && team.students.length > 0) {
                worksheet.addRow({
                    name: 'Student Name',
                    ageUndertaken: 'Age',
                    gender: 'Gender',
                    studentCount: 'Phone'
                });
                
                // Get and add student rows
                for (const studentId of team.students) {
                    const studentRef = doc(db, 'students', studentId);
                    const studentDoc = await getDoc(studentRef);
                    
                    if (studentDoc.exists()) {
                        const studentData = studentDoc.data();
                        worksheet.addRow({
                            name: studentData.name,
                            ageUndertaken: studentData.age,
                            gender: studentData.gender,
                            studentCount: studentData.phone
                        });
                    }
                }
            } else {
                worksheet.addRow({ name: 'No students in this team' });
            }
            
            // Add separator
            worksheet.addRow({});
        }
        
        // Set response headers
        res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        res.setHeader('Content-Disposition', 'attachment; filename=teams.xlsx');
        
        // Write to response
        await workbook.xlsx.write(res);
        res.end();
        
    } catch (error) {
        console.error('Error exporting teams data:', error);
        res.redirect('/principal/dashboard?message=Failed+to+export+teams+data&messageType=danger');
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