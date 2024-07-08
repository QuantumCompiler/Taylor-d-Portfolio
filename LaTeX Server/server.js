const express = require('express');
const multer = require('multer');
const fs = require('fs');
const { exec } = require('child_process');

const app = express();
const upload = multer({ dest: 'uploads/' });

app.post('/compile', upload.single('file'), (req, res) => {
    const filePath = req.file.path;
    const outputPath = `${filePath}.pdf`;

    exec(`lualatex -output-directory=uploads ${filePath}`, (error, stdout, stderr) => {
        if (error) {
        console.error(`exec error: ${error}`);
        return res.status(500).send(stderr);
        }

        fs.readFile(outputPath, (err, data) => {
        if (err) {
            console.error(`readFile error: ${err}`);
            return res.status(500).send(err);
        }

        res.contentType('application/pdf');
        res.send(data);

        // Clean up temporary files
        fs.unlinkSync(filePath);
        fs.unlinkSync(outputPath);
        });
    });
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});