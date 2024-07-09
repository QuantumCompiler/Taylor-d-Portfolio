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
        cb(null, "Input.zip");
    }
});

const upload = multer({ storage: storage });
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

async function unZipInput() {
    return new Promise((resolve, reject) => {
        process.chdir('uploads/')
        exec('mkdir Input && unzip Input.zip -d Input && rm -rf Input.zip', (error, stdout, stderr) => {
            if (error) {
                console.error(error);
                reject(error);
            }
            else if (stderr) {
                console.stderr(stderr);
                resolve(stderr);
            }
            else {
                console.log('Sent documents, unzipped, and removed initial files successfully.');
                process.chdir('..');
                resolve(stdout);
            }
        });
    });
}

async function compileLaTeX() {
    return new Promise((resolve, reject) => {
        process.chdir('uploads/Input/');
        exec('lualatex main.tex', (error, stdout, stderr) => {
            console.log(`stdout: ${stdout}`);
            console.log('LaTeX file compiled successfully.')
            process.chdir('..');
            process.chdir('..');
            resolve(stdout);
        });
    });
}

async function zipReturn() {
    return new Promise((resolve, reject) => {
        process.chdir('uploads/');
        exec('mv Input Return && zip -r Return.zip Return && rm -rf Return', (error, stdout, stderr) => {
            if (error) {
                console.error(error);
                reject(error);
            }
            else if (stderr) {
                console.stderr(stderr);
                resolve(stderr);
            }
            else {
                console.log('Return file zipped and master dir deleted successfully.');
                process.chdir('..');
                resolve(stdout);
            }
        });
    });
}

app.post('/compile', upload.single('file'), async (req, res) => {
    try {
        await unZipInput();
        await compileLaTeX();
        await zipReturn();
        const returnZipPath = path.join(__dirname, 'uploads', 'Return.zip');
        res.download(returnZipPath, 'Return.zip', (err) => {
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