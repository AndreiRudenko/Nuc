let project = new Project('nuclib');

project.addFile('src/**');
project.addIncludeDir('src');

resolve(project);