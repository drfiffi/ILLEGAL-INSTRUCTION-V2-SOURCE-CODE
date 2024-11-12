package shaders;

import flixel.system.FlxAssets.FlxShader;

class GrayscaleShader 
{
    public var shader(default, null):GrayscaleShad = null;
    public function new()
    {
        shader = new GrayscaleShad();
        shader.iTime.value = [0];
    }
    public function update(elapsed:Float)
    {
        shader.iTime.value[0] += elapsed;
    }
}

class GrayscaleShad extends FlxShader
{
	@:glFragmentSource('
	#pragma header
    uniform float iTime;

    float circle(in vec2 _st, in float _radius, vec2 pos){
        vec2 dist = _st-pos;
        return (1.-smoothstep(_radius-(_radius),_radius+(
            _radius*0.1)+0.2,dot(dist,dist)));
    }
    
    void main()
    {
        vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
        if (circle(openfl_TextureCoordv.xy,(iTime-0.3)/2.,vec2(0.5)) > 0.)
        color = vec4(vec3(dot(color.rgb, vec3(.5, .5, .5))), color.a);
        gl_FragColor = color;
    }
	')
	public function new()
    {
		super();
	}
}