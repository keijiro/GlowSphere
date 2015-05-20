//
// Burst - line burst effect.
//

using UnityEngine;

namespace Kvant {

    [ExecuteInEditMode, AddComponentMenu("Kvant/Burst")]
    public class Burst : MonoBehaviour
    {
        #region Parameters Exposed To Editor

        [SerializeField] int _maxBeams = 32768;

        [SerializeField] float _throttle = 1.0f;
        [SerializeField] float _radius = 1.0f;

        [ColorUsage(true, true, 0, 8, 0.125f, 3)]
        [SerializeField] Color _color = Color.white;

        [SerializeField] int _randomSeed = 0;
        [SerializeField] bool _debug;

        #endregion

        #region Shader And Materials

        [SerializeField] Shader _kernelShader;
        [SerializeField] Shader _lineShader;
        [SerializeField] Shader _debugShader;

        Material _kernelMaterial;
        Material _lineMaterial;
        Material _debugMaterial;

        #endregion

        #region Private Variables And Objects

        RenderTexture _beamBuffer1;
        RenderTexture _beamBuffer2;
        Mesh _mesh;
        bool _needsReset = true;

        #endregion

        #region Resource Management

        public void NotifyConfigChange()
        {
            _needsReset = true;
        }

        int BufferWidth { get { return 256; } }

        int BufferHeight {
            get { return Mathf.Clamp(_maxBeams / BufferWidth + 1, 1, 127); }
        }

        Material CreateMaterial(Shader shader)
        {
            var material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
            return material;
        }

        RenderTexture CreateBuffer()
        {
            var buffer = new RenderTexture(BufferWidth, BufferHeight, 0, RenderTextureFormat.ARGBFloat);
            buffer.hideFlags = HideFlags.DontSave;
            buffer.filterMode = FilterMode.Point;
            buffer.wrapMode = TextureWrapMode.Repeat;
            return buffer;
        }

        Mesh CreateMesh()
        {
            var Nx = BufferWidth;
            var Ny = BufferHeight;

            // Create vertex arrays.
            var VA = new Vector3[Nx * Ny * 2];
            var TA = new Vector2[Nx * Ny * 2];

            var Ai = 0;
            for (var x = 0; x < Nx; x++)
            {
                for (var y = 0; y < Ny; y++)
                {
                    VA[Ai + 0] = new Vector3(0, 0, 0);
                    VA[Ai + 1] = new Vector3(1, 0, 0);

                    var u = (float)x / Nx;
                    var v = (float)y / Ny;
                    TA[Ai] = TA[Ai + 1] = new Vector2(u, v);

                    Ai += 2;
                }
            }

            // Index array.
            var IA = new int[VA.Length];
            for (Ai = 0; Ai < VA.Length; Ai++) IA[Ai] = Ai;

            // Create a mesh object.
            var mesh = new Mesh();
            mesh.hideFlags = HideFlags.DontSave;
            mesh.vertices = VA;
            mesh.uv = TA;
            mesh.SetIndices(IA, MeshTopology.Lines, 0);
            mesh.Optimize();

            // Avoid being culled.
            mesh.bounds = new Bounds(Vector3.zero, Vector3.one * 1000);

            return mesh;
        }

        void ApplyKernelParameters()
        {
            var delta = Application.isPlaying ? Time.smoothDeltaTime : 1.0f / 30;
            _kernelMaterial.SetVector("_Config", new Vector4(_randomSeed, _throttle, delta, 0));
        }

        void ResetResources()
        {
            // Mesh object.
            if (_mesh == null) _mesh = CreateMesh();

            // Beam buffers.
            if (_beamBuffer1) DestroyImmediate(_beamBuffer1);
            if (_beamBuffer2) DestroyImmediate(_beamBuffer2);
            _beamBuffer1 = CreateBuffer();
            _beamBuffer2 = CreateBuffer();

            // Shader materials.
            if (!_kernelMaterial) _kernelMaterial = CreateMaterial(_kernelShader);
            if (!_lineMaterial)   _lineMaterial   = CreateMaterial(_lineShader);
            if (!_debugMaterial)  _debugMaterial  = CreateMaterial(_debugShader);

            // Initialization.
            ApplyKernelParameters();
            Graphics.Blit(null, _beamBuffer2, _kernelMaterial, 0);

            _needsReset = false;
        }

        #endregion

        #region MonoBehaviour Functions

        void Reset()
        {
            _needsReset = true;
        }

        void OnDestroy()
        {
            if (_mesh)           DestroyImmediate(_mesh);
            if (_beamBuffer1)    DestroyImmediate(_beamBuffer1);
            if (_beamBuffer2)    DestroyImmediate(_beamBuffer2);
            if (_kernelMaterial) DestroyImmediate(_kernelMaterial);
            if (_lineMaterial)   DestroyImmediate(_lineMaterial);
            if (_debugMaterial)  DestroyImmediate(_debugMaterial);
        }

        void Update()
        {
            if (_needsReset) ResetResources();

            ApplyKernelParameters();

            if (Application.isPlaying)
            {
                // Swap the beam buffers.
                var temp = _beamBuffer1;
                _beamBuffer1 = _beamBuffer2;
                _beamBuffer2 = temp;

                // Apply the kernel shader.
                Graphics.Blit(_beamBuffer1, _beamBuffer2, _kernelMaterial, 1);
            }
            else
            {
                // Editor: initialize the buffer on every update.
                Graphics.Blit(null, _beamBuffer2, _kernelMaterial, 0);
            }

            // Draw beams.
            _lineMaterial.SetTexture("_BeamTex", _beamBuffer2);
            _lineMaterial.SetColor("_Color", _color);
            _lineMaterial.SetFloat("_Radius", _radius);
            Graphics.DrawMesh(_mesh, transform.position, transform.rotation, _lineMaterial, 0);
        }

        void OnGUI()
        {
            if (_debug && Event.current.type.Equals(EventType.Repaint)) {
                if (_debugMaterial && _beamBuffer2) {
                    var rect = new Rect(0, 0, 256, 64);
                    Graphics.DrawTexture(rect, _beamBuffer2, _debugMaterial);
                }
            }
        }

        #endregion
    }
}
