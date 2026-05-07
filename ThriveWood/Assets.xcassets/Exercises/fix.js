const fs = require('fs');
const path = require('path');

// Get all parent folders, ignoring hidden files and existing .imagesets just in case
const dirs = fs.readdirSync('.', { withFileTypes: true })
    .filter(dirent => dirent.isDirectory() && !dirent.name.endsWith('.imageset') && !dirent.name.startsWith('.'))
    .map(dirent => dirent.name);

dirs.forEach(d => {
    // 1. Ensure the parent folder has the namespace property
    const namespaceContents = {
        info: { author: "xcode", version: 1 },
        properties: { "provides-namespace": true }
    };
    fs.writeFileSync(path.join(d, 'Contents.json'), JSON.stringify(namespaceContents, null, 2));

    // 2. Find all loose files in the directory
    const files = fs.readdirSync(d)
        .filter(f => {
            const isFile = fs.statSync(path.join(d, f)).isFile();
            return isFile && !f.startsWith('.') && f !== 'Contents.json';
        });

    files.forEach(file => {
        // Strip the extension and any @2x/@3x to get the base imageset name (e.g., '0' from '0@2x.png')
        const ext = path.extname(file);
        const baseName = path.basename(file, ext);
        const imageSetNameBase = baseName.replace(/@2x|@3x/g, '');
        const imageSetDir = path.join(d, `${imageSetNameBase}.imageset`);

        // Create the .imageset folder if it doesn't exist yet
        if (!fs.existsSync(imageSetDir)) {
            fs.mkdirSync(imageSetDir);
        }

        // Move the image file into the .imageset folder
        const oldPath = path.join(d, file);
        const newPath = path.join(imageSetDir, file);
        fs.renameSync(oldPath, newPath);

        // Prepare or read the Contents.json for this specific image set
        const imagesetContentsPath = path.join(imageSetDir, 'Contents.json');
        let imagesetContents = {
            info: { author: "xcode", version: 1 },
            images: []
        };

        if (fs.existsSync(imagesetContentsPath)) {
            imagesetContents = JSON.parse(fs.readFileSync(imagesetContentsPath, 'utf8'));
        }

        // Determine the scale
        let scale = "1x";
        if (file.includes("@2x")) scale = "2x";
        else if (file.includes("@3x")) scale = "3x";

        // Add the image to the array (or update it if we run the script twice)
        const existingImageIndex = imagesetContents.images.findIndex(img => img.scale === scale);
        if (existingImageIndex >= 0) {
            imagesetContents.images[existingImageIndex].filename = file;
        } else {
            imagesetContents.images.push({
                filename: file,
                idiom: "universal",
                scale: scale
            });
        }

        // Write the Contents.json back to the .imageset folder
        fs.writeFileSync(imagesetContentsPath, JSON.stringify(imagesetContents, null, 2));
    });
});

console.log(`Successfully converted loose images into .imageset structures across ${dirs.length} folders!`);
