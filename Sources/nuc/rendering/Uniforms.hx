package nuc.rendering;

import kha.graphics4.ConstantLocation;
import kha.graphics4.TextureUnit;
import kha.graphics4.PipelineState;
import kha.graphics4.Graphics;

import nuc.utils.Float32Array;
import nuc.utils.FastFloat;
import nuc.math.Matrix3;
import nuc.math.Matrix4;
import nuc.graphics.Texture;
import nuc.utils.ArrayTools;

class Uniforms {

	var pipeline:PipelineState;

	var boolMap:Map<String, Uniform<Bool, ConstantLocation>>;
	var intMap:Map<String, Uniform<Int, ConstantLocation>>;
	var floatMap:Map<String, Uniform<FastFloat, ConstantLocation>>;
	var float2Map:Map<String, Uniform<Array<FastFloat>, ConstantLocation>>;
	var float3Map:Map<String, Uniform<Array<FastFloat>, ConstantLocation>>;
	var float4Map:Map<String, Uniform<Array<FastFloat>, ConstantLocation>>;
	var floatsMap:Map<String, Uniform<Float32Array, ConstantLocation>>;
	var matrix4Map:Map<String, Uniform<Matrix4, ConstantLocation>>;
	var matrix3Map:Map<String, Uniform<Matrix3, ConstantLocation>>;

	var textureMap:Map<String, Uniform<Texture,TextureUnit>>;
	var textureParamsMap:Map<String, Uniform<TextureParameters,TextureUnit>>;

	var dirtyUniforms:Array<UniformBase>;

	public function new(pipeline:PipelineState) {
		this.pipeline = pipeline;
		clear();
	}

	public function clear() {
		boolMap = new Map();
		intMap = new Map();
		floatMap = new Map();
		float2Map = new Map();
		float3Map = new Map();
		float4Map = new Map();
		floatsMap = new Map();
		matrix3Map = new Map();
		matrix4Map = new Map();
		textureMap = new Map();
		textureParamsMap = new Map();

		dirtyUniforms = [];
	}
	
	public inline function setBool(name:String, value:Bool) {
		var bool = boolMap.get(name);

		if(bool != null) {
			bool.value = value;
		} else {
			var location = pipeline.getConstantLocation(name);
			bool = new UniformBool(value, location);
			boolMap.set(name, bool);
		}

		if(!bool.used) {
			dirtyUniforms.push(bool);
			bool.used = true;
		}

		return bool;
	}

	public inline function getBool(name:String):Uniform<Bool, ConstantLocation> {
		return boolMap.get(name);
	}

	public inline function setInt(name:String, value:Int) {
		var int = intMap.get(name);

		if(int != null) {
			int.value = value;
		} else {
			var location = pipeline.getConstantLocation(name);
			int = new UniformInt(value, location);
			intMap.set(name, int);
		}

		if(!int.used) {
			dirtyUniforms.push(int);
			int.used = true;
		}

		return int;
	}

	public inline function getInt(name:String):Uniform<Int, ConstantLocation> {
		return intMap.get(name);
	}

	public inline function setFloat(name:String, value:FastFloat) {
		var float = floatMap.get(name);

		if(float != null) {
			float.value = value;
		} else {
			var location = pipeline.getConstantLocation(name);
			float = new UniformFloat(value, location);
			floatMap.set(name, float);
		}

		if(!float.used) {
			dirtyUniforms.push(float);
			float.used = true;
		}

		return float;
	}

	public inline function getFloat(name:String):Uniform<FastFloat, ConstantLocation> {
		return floatMap.get(name);
	}

	public inline function setFloat2(name:String, value:Array<FastFloat>) {
		var float2 = float2Map.get(name);

		if(float2 != null) {
			float2.value = value;
		} else {
			var location = pipeline.getConstantLocation(name);
			float2 = new UniformFloat2(value, location);
			float2Map.set(name, float2);
		}

		if(!float2.used) {
			dirtyUniforms.push(float2);
			float2.used = true;
		}

		return float2;
	}
	
	public inline function getFloat2(name:String):Uniform<Array<FastFloat>, ConstantLocation> {
		return float2Map.get(name);
	}

	public inline function setFloat3(name:String, value:Array<FastFloat>) {
		var float3 = float3Map.get(name);

		if(float3 != null) {
			float3.value = value;
		} else {
			var location = pipeline.getConstantLocation(name);
			float3 = new UniformFloat3(value, location);
			float3Map.set(name, float3);
		}

		if(!float3.used) {
			dirtyUniforms.push(float3);
			float3.used = true;
		}

		return float3;
	}
	
	public inline function getFloat3(name:String):Uniform<Array<FastFloat>, ConstantLocation> {
		return float3Map.get(name);
	}

	public inline function setFloat4(name:String, value:Array<FastFloat>) {
		var float4 = float4Map.get(name);

		if(float4 != null) {
			float4.value = value;
		} else {
			var location = pipeline.getConstantLocation(name);
			float4 = new UniformFloat4(value, location);
			float4Map.set(name, float4);
		}

		if(!float4.used) {
			dirtyUniforms.push(float4);
			float4.used = true;
		}

		return float4;
	}

	public inline function getFloat4(name:String):Uniform<Array<FastFloat>, ConstantLocation> {
		return float4Map.get(name);
	}
	
	public inline function setFloats(name:String, value:Float32Array) {
		var floats = floatsMap.get(name);

		if(floats != null) {
			floats.value = value;
		} else {
			var location = pipeline.getConstantLocation(name);
			floats = new UniformFloats(value, location);
			floatsMap.set(name, floats);
		}

		if(!floats.used) {
			dirtyUniforms.push(floats);
			floats.used = true;
		}

		return floats;
	}

	public inline function getFloats(name:String):Uniform<Float32Array, ConstantLocation> {
		return floatsMap.get(name);
	}

	public inline function setMatrix3(name:String, value:Matrix3) {
		var matrix3 = matrix3Map.get(name);

		if(matrix3 != null) {
			matrix3.value = value;
		} else {
			var location = pipeline.getConstantLocation(name);
			matrix3 = new UniformMatrix3(value, location);
			matrix3Map.set(name, matrix3);
		}

		if(!matrix3.used) {
			dirtyUniforms.push(matrix3);
			matrix3.used = true;
		}

		return matrix3;
	}

	public inline function getMatrix3(name:String):Uniform<Matrix3, ConstantLocation> {
		return matrix3Map.get(name);
	}

	public inline function setMatrix4(name:String, value:Matrix4) {
		var matrix4 = matrix4Map.get(name);

		if(matrix4 != null) {
			matrix4.value = value;
		} else {
			var location = pipeline.getConstantLocation(name);
			matrix4 = new UniformMatrix4(value, location);
			matrix4Map.set(name, matrix4);
		}

		if(!matrix4.used) {
			dirtyUniforms.push(matrix4);
			matrix4.used = true;
		}

		return matrix4;
	}

	public inline function getMatrix4(name:String):Uniform<Matrix4, ConstantLocation> {
		return matrix4Map.get(name);
	}

	public inline function setTexture(name:String, value:Texture) {
		var texture = textureMap.get(name);

		if(texture != null) {
			texture.value = value;
		} else {
			var location = pipeline.getTextureUnit(name);
			texture = new UniformTexture(value, location);
			textureMap.set(name, texture);
		}

		if(!texture.used) {
			dirtyUniforms.push(texture);
			texture.used = true;
		}

		return texture;
	}

	public inline function getTexture(name:String):Uniform<Texture,TextureUnit> {
		return textureMap.get(name);
	}

	public inline function setTextureParameters(name:String, value:TextureParameters) {
		var texParams = textureParamsMap.get(name);

		if(texParams != null) {
			texParams.value = value;
		} else {
			var location = pipeline.getTextureUnit(name);
			texParams = new UniformTextureParameters(value, location);
			textureParamsMap.set(name, texParams);
		}

		if(!texParams.used) {
			dirtyUniforms.push(texParams);
			texParams.used = true;
		}

		return texParams;
	}

	public inline function getTextureParameters(name:String):Uniform<TextureParameters,TextureUnit> {
		return textureParamsMap.get(name);
	}

	public inline function apply(g:Graphics) {
		if(dirtyUniforms.length > 0) {
			var i = 0;
			var u:UniformBase;
			while(i < dirtyUniforms.length) {
				u = dirtyUniforms[i];
				u.commit(g);
				u.used = false;
				i++;
			}
			ArrayTools.clear(dirtyUniforms);
		}
	}

}

private class UniformBase {

	public var used:Bool = false;
	public function commit(g:Graphics) {}

}

private class Uniform<T, T1> extends UniformBase {

	public var value:T;
	public var location:T1;

	public function new(value:T, location:T1) {
		this.value = value;
		this.location = location;
	}

}

private class UniformBool extends Uniform<Bool, ConstantLocation> {

	override function commit(g:Graphics) {
		g.setBool(location, value);
	}

}

private class UniformInt extends Uniform<Int, ConstantLocation> {

	override function commit(g:Graphics) {
		g.setInt(location, value);
	}

}

private class UniformFloat extends Uniform<FastFloat, ConstantLocation> {

	override function commit(g:Graphics) {
		g.setFloat(location, value);
	}

}

private class UniformFloat2 extends Uniform<Array<FastFloat>, ConstantLocation> {

	override function commit(g:Graphics) {
		g.setFloat2(location, value[0], value[1]);
	}

}

private class UniformFloat3 extends Uniform<Array<FastFloat>, ConstantLocation> {

	override function commit(g:Graphics) {
		g.setFloat3(location, value[0], value[1], value[2]);
	}

}

private class UniformFloat4 extends Uniform<Array<FastFloat>, ConstantLocation> {

	override function commit(g:Graphics) {
		g.setFloat4(location, value[0], value[1], value[2], value[3]);
	}

}


private class UniformFloats extends Uniform<Float32Array, ConstantLocation> {

	override function commit(g:Graphics) {
		g.setFloats(location, value);
	}

}

private class UniformMatrix3 extends Uniform<Matrix3, ConstantLocation> {

	override function commit(g:Graphics) {
		g.setMatrix3(location, value);
	}

}

private class UniformMatrix4 extends Uniform<Matrix4, ConstantLocation> {

	override function commit(g:Graphics) {
		g.setMatrix(location, value);
	}

}

private class UniformTexture extends Uniform<Texture, TextureUnit> {

	override function commit(g:Graphics) {
		g.setTexture(location, value != null ? value.image : null);
	}

}

private class UniformTextureParameters extends Uniform<TextureParameters, TextureUnit> {

	override function commit(g:Graphics) {
		g.setTextureParameters(location, value.uAddressing, value.vAddressing, value.filterMin, value.filterMag, value.mipmapFilter);
	}

}

class TextureParameters {

	public var uAddressing:TextureAddressing = TextureAddressing.Clamp;
	public var vAddressing:TextureAddressing = TextureAddressing.Clamp;
	public var filterMin:TextureFilter = TextureFilter.LinearFilter;
	public var filterMag:TextureFilter = TextureFilter.LinearFilter;
	public var mipmapFilter:MipMapFilter = MipMapFilter.NoMipFilter;

	public function new() {

	}

}