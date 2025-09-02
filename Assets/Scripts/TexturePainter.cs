using UnityEngine;
using WaterInput;
using UnityEngine.InputSystem;

public class TexturePainter : MonoBehaviour
{
    public Camera mainCamera;
    public Material drawingMaterial;    
    public Material simMaterial;       
    public RenderTexture displacementRT; 

    private RenderTexture[] buffers = new RenderTexture[2];
    private bool[] createdByScript = new bool[2]; 
    private int current = 0;

    private MultiplatformInput inputActions;
    private bool isPainting = false;

    private void Awake()
    {
        inputActions = new MultiplatformInput();
        inputActions.Player.Enable();
        inputActions.Player.Paint.performed += OnPaintPerformed;
        inputActions.Player.Paint.canceled += OnPaintCanceled;


        if (displacementRT != null)
        {
            if (!displacementRT.IsCreated())
                displacementRT.Create();

            buffers[0] = displacementRT;
            createdByScript[0] = false;

            buffers[1] = CreateRenderTextureLike(displacementRT);
            createdByScript[1] = true;
        }
        else
        {
            int w = 512;
            int h = 512;
            RenderTextureFormat fmt = RenderTextureFormat.ARGBFloat; 
            buffers[0] = CreateRenderTexture(w, h, fmt);
            buffers[1] = CreateRenderTexture(w, h, fmt);
            createdByScript[0] = createdByScript[1] = true;

            displacementRT = buffers[0];
        }

        current = 0;

        ClearRenderTexture(buffers[current]);
    }

    private void OnDestroy()
    {
        if (inputActions != null)
        {
            inputActions.Player.Paint.performed -= OnPaintPerformed;
            inputActions.Player.Paint.canceled -= OnPaintCanceled;
            inputActions.Dispose();
            inputActions = null;
        }

        for (int i = 0; i < 2; i++)
        {
            if (buffers[i] != null && createdByScript[i])
            {
                buffers[i].Release();
                buffers[i] = null;
            }
        }
    }

    private void Update()
    {
        int next = 1 - current;

        if (isPainting)
        {
            Vector2 screenPos = inputActions.Player.Position.ReadValue<Vector2>();

            Ray ray = mainCamera.ScreenPointToRay(screenPos);
            if (Physics.Raycast(ray, out RaycastHit hit))
            {

                drawingMaterial.SetVector("_BrushPos", new Vector4(hit.textureCoord.x, hit.textureCoord.y, 0, 0));
                Graphics.Blit(buffers[current], buffers[next], drawingMaterial);
                current = next;
                next = 1 - current;
            }
        }

        Graphics.Blit(buffers[current], buffers[next], simMaterial);

        current = next;

        if (displacementRT != buffers[current])
        {
            Graphics.Blit(buffers[current], displacementRT);
        }
    }

    #region Input Callbacks
    private void OnPaintPerformed(InputAction.CallbackContext ctx) => isPainting = true;
    private void OnPaintCanceled(InputAction.CallbackContext ctx) => isPainting = false;
    #endregion

    #region Helpers
    private RenderTexture CreateRenderTextureLike(RenderTexture reference)
    {
        var rt = new RenderTexture(reference.width, reference.height, 0, reference.format)
        {
            enableRandomWrite = false,
            filterMode = reference.filterMode,
            wrapMode = reference.wrapMode
        };
        rt.Create();
        return rt;
    }

    private RenderTexture CreateRenderTexture(int width, int height, RenderTextureFormat format)
    {
        var rt = new RenderTexture(width, height, 0, format)
        {
            enableRandomWrite = false,
            filterMode = FilterMode.Bilinear,
            wrapMode = TextureWrapMode.Clamp
        };
        rt.Create();
        return rt;
    }

    private void ClearRenderTexture(RenderTexture rt)
    {
        if (rt == null) return;
        RenderTexture prev = RenderTexture.active;
        RenderTexture.active = rt;
        GL.Clear(true, true, Color.black);
        RenderTexture.active = prev;
    }
    #endregion
}
