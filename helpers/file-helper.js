const fs = require('fs');
const path = require('path');

function readIntervalsFromFile(fileName) {
    const filePath = path.join(__dirname, "..", "config", 'mapping', fileName);

    try {
        const fileData = fs.readFileSync(filePath, 'utf8');
        const intervalsArray = JSON.parse(fileData);
        return intervalsArray;
    } catch (error) {
        console.error('Error reading or parsing the file:', error);
        return null;
    }
}

module.exports = {
    readIntervalsFromFile
};