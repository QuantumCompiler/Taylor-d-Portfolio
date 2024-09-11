const express = require('express');
const multer = require('multer');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');
const app = express();

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, './uploads');
    },
    filename: function (req, file, cb) {
        const inputFileName = req.query.inputFileName || 'Input.zip';
        const returnFileName = req.query.returnFileName || 'Return.zip';
        console.log(`Input Zip Name: ${inputFileName}`);
        console.log(`Output Zip Name: ${returnFileName}`);
        cb(null, inputFileName);
    }
});

const upload = multer({ storage: storage });
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

async function unZipInput(inputFileName) {
    return new Promise((resolve, reject) => {
        const inputFilePath = path.join('uploads', inputFileName);
        console.log(`Unzipping file: ${inputFilePath}`);
        
        if (!fs.existsSync(inputFilePath)) {
            return reject(new Error(`File not found: ${inputFilePath}`));
        }

        process.chdir('uploads/');
        exec(`rm -rf Input && mkdir Input && unzip "${inputFileName}" -d Input && rm -rf "${inputFileName}"`, (error, stdout, stderr) => {
            if (error) {
                console.error(`Error during unzip: ${error}`);
                reject(error);
            } else if (stderr) {
                console.error(`Unzip stderr: ${stderr}`);
                resolve(stderr);
            } else {
                console.log('Documents unzipped and initial files removed successfully.');
                process.chdir('..');
                resolve(stdout);
            }
        });
    });
}

async function compileLaTeX() {
    return new Promise((resolve, reject) => {
        process.chdir('uploads/Input/');
        exec('lualatex main.tex && lualatex main.tex', (error, stdout, stderr) => {
            console.log(`stdout: ${stdout}`);
            console.log('LaTeX file compiled successfully.')
            process.chdir('..');
            process.chdir('..');
            resolve(stdout);
        });
    });
}

async function zipReturn(returnFileName) {
    return new Promise((resolve, reject) => {
        process.chdir('uploads/');
        const returnDirName = path.parse(returnFileName).name;
        exec(`mv Input "${returnDirName}" && zip -r "${returnFileName}" "${returnDirName}" && rm -rf "${returnDirName}"`, (error, stdout, stderr) => {
            if (error) {
                console.error(error);
                reject(error);
            } else if (stderr) {
                console.error(stderr);
                resolve(stderr);
            } else {
                console.log('Return file zipped and master dir deleted successfully.');
                process.chdir('..');
                resolve(stdout || stderr);
            }
        });
    });
}

app.post('/compile', upload.single('file'), async (req, res) => {
    const inputFileName = req.query.inputFileName || 'Input.zip';
    const returnFileName = req.query.returnFileName || 'Return.zip';
    try {
        console.log(`Received file: ${req.file.originalname}`);
        await unZipInput(inputFileName);
        await compileLaTeX();
        await zipReturn(returnFileName);
        const returnZipPath = path.join(__dirname, 'uploads', returnFileName);
        res.download(returnZipPath, returnFileName, (err) => {
            if (err) {
                console.error(`Error sending file: ${err}`);
                res.status(500).send('Internal Server Error');
            } else {
                console.log('File sent successfully.');
                fs.unlinkSync(returnZipPath);
            }
        });
    } catch (error) {
        console.error(`Error processing request: ${error}`);
        if (!res.headersSent) {
            res.status(500).send('Internal Server Error');
        }
    }
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});