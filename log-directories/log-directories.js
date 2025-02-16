console.log("Node Version:", process.version);

import { readdirSync, statSync } from "fs";
import { join } from "path";

/**
 * Recursively logs the folder structure starting from the given directory.
 *
 * @param {string} dir - The directory to start from.
 * @param {string} indent - The indent string (used for nested folders).
 */
function logFolderStructure(dir, indent = "") {
  // Read all items in the directory
  const items = readdirSync(dir);
  items.forEach((item) => {
    const fullPath = join(dir, item);
    const stat = statSync(fullPath);
    if (stat.isDirectory()) {
      console.log(indent + "📁 " + item);
      // Recursively log subdirectory contents with increased indentation
      logFolderStructure(fullPath, indent + "  ");
    } else {
      console.log(indent + "📄 " + item);
    }
  });
}

// Log the folder structure starting from the current working directory
console.log("\nFolder Structure:");
logFolderStructure(process.cwd());
