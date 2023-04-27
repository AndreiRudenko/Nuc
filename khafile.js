let p = new Project("nuc");
p.addSources("Sources");

p.addLibrary("nuclib"); 
p.addShaders("Sources/Shaders/**");

p.addAssets(
    "Assets/**", 
    {
        nameBaseDir: "assets", 
        destination: "assets/{dir}/{name}", 
        name: "{dir}/{name}", 
        noprocessing: true, 
        notinlist: true
    }
);
resolve(p);