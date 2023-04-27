let p = new Project("nuc");
p.addSources("Sources");

p.addLibrary("nuclib"); 
p.addShaders("Sources/Shaders/**");

p.addAssets(
    "Assets/**", 
    {
        nameBaseDir: "Assets", 
        destination: "Assets/{name}", 
        noprocessing: true, 
        notinlist: true
    }
);
resolve(p);