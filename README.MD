Nuc is a lightweight cross-platform, 2d game framework.  
Build on top of [Kha](https://github.com/Kode/Kha) framework using [Haxe](https://haxe.org/) language. 
 
## Installation
- Install [Kha](https://github.com/Kode/Kha/wiki/Getting-Started)
- Init Kha Project
- Clone Nuc to your project folder:
	```bash
	git clone https://github.com/nuclibs/Nuc.git
	```
- Open [khafile.js](https://github.com/Kode/Kha/wiki/khafile.js) from your project folder and add this lines:

	```js
	let p = new Project("New Project");

	await p.addProject("Nuc");

	p.addSources("Sources");
	p.addShaders("Shaders");
	p.addAssets(
		"Assets/**",
		{
			nameBaseDir: "Assets", 
			destination: "Assets/{dir}/{name}", 
			name: "{dir}/{name}", 
			noprocessing: true, 
			notinlist: true
		}
	);

	resolve(p);
	```
	
## Minimal example
```haxe

import nuc.Resources;
import nuc.Window;
import nuc.events.AppEvent;
import nuc.events.RenderEvent;
import nuc.graphics.SpriteBatch;
import nuc.graphics.Camera;
import nuc.graphics.Texture;

class Game {

	var camera:Camera;
	var sb:SpriteBatch;
	var parrotImage:Texture;

	public function new() {
		Resources.loadAll(
			[
				'parrot.png'
			], 
			ready
		);
	}

	function ready() {
		App.on(AppEvent.UPDATE, update);
		App.on(RenderEvent.RENDER, render);

		camera = new Camera(Window.width, Window.height);
		camera.clearColor = new Color(0.2, 0.2, 0.2, 1.0);

		sb = new SpriteBatch();

		parrotImage = Resources.getTexture('parrot.png');
	}

	function update(elapsed:Float) {

	}
		
	function render(e:RenderEvent) {
		camera.begin();

		sb.drawImage(parrotImage);

		camera.end();
	}
	
}

```

---
This framework is in development and is not ready for production.  
I'm using it for my own projects and if you like this project and you want to contribute, feel free to do so.  