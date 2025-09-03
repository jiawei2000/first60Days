const express = require('express');
const db = require('../database');
const router = express.Router()
const { authenticateToken } = require('./auth');


//get a list of permissions belonging to the userId 
router.get('permissions/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.params;
    try {
        const permissionsRef = db.collection("permissions")
        const snapshot = await permissionsRef.where("userID", "==", userId).get();

        if (snapshot.empty) {
            return res.status(404).json({ message: "No permissions found" });
        }
        // Format the results
        const entries = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        res.status(200).json(entries);

    }
    catch (error) {
        res.status(400).json({ error: error.message });
    }

})

//Main User creates new permissions for sub user  
router.post('permission/newPermission', authenticateToken, async (req, res) => {
    //optional: check permissionType of userID is main 


})

//Main User updates permissions for sub user 

//Main User deletes permission 





module.exports = router;