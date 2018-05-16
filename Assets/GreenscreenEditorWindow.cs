using UnityEngine;
using UnityEditor;

public class GreenscreenEditorWindow : EditorWindow
{
    // Main editor window instance
    private static EditorWindow greenscreenEditorWindow;

    // Camera texture and its properties
    private WebCamTexture cameraTexture;
    private string cameraName;

    // Chroma Key material with shader for greenscreen
    private Material chromaKeyMaterial;

    // Webcam devices
    private static string[] deviceNames;
    private int deviceIndex = 0;

    // Chroma Key Color (color replaced with background)
    private Color chromaKeyColor = Color.green;
    private float chromaKeyTolerance = 0.4f;

    // Add menu item
    [MenuItem("Mixed Reality Framework / Camera View")]
    static void Init()
    {
        // Get camera names and initialize and instanciate editor window
        deviceNames = getCameraNames();
        greenscreenEditorWindow = EditorWindow.CreateInstance<GreenscreenEditorWindow>();
        greenscreenEditorWindow.Show();
    }

    void OnGUI()
    {
        {
            // Titel of the editor window
            GUILayout.Label("Mixed Reality Calibration - Camera View", EditorStyles.boldLabel);

            // Dropdown to choose camera
            deviceIndex = EditorGUILayout.Popup(deviceIndex, deviceNames);
            // Get camera name and set cameraView
            if (GUILayout.Button("Show my camera view"))
                setCameraView();
            EditorGUILayout.Space();

            // Colorpicker (color to be replaced with bachground)
            chromaKeyColor = EditorGUILayout.ColorField("Set Chroma Key Color", chromaKeyColor);
            EditorGUILayout.Space();

            // Tolerance Slider
            GUILayout.Label("Chroma Key Tolerance (tolerated rgb difference to given color)");
            chromaKeyTolerance = EditorGUILayout.Slider(chromaKeyTolerance, 0.0f, 1.0f);

            // Camera view
            if (cameraTexture != null)
                EditorGUI.DrawPreviewTexture(
                    // Position and size
                    new Rect(20, 150, position.width - 40, position.height - 200),
                    // Video Texture
                    cameraTexture, 
                    // Matrerial with chroma key shader
                    chromaKeyMaterial, 
                    // Scale texture to given size
                    ScaleMode.ScaleAndCrop
                );
                EditorGUILayout.Space();
        }
    }

    private void Update()
    {
        // If camera view is visible and rendereing: reset color and tolerance if changed 
        if (cameraTexture != null && cameraTexture.isPlaying && chromaKeyMaterial != null) {
            chromaKeyMaterial.SetColor("_mainColor", chromaKeyColor);
            chromaKeyMaterial.SetFloat("_tolerance", chromaKeyTolerance);
        }

        // Make sure the camera view is always shown and updated
        Repaint();
    }

    private void setCameraView()
    {
        // If camera is already playing: stop it
        if (cameraTexture != null && cameraTexture.isPlaying) {
            cameraTexture.Stop();
        }

        // Initialize camera textrue and play camera
        cameraName = deviceNames[deviceIndex];
        cameraTexture = new WebCamTexture(cameraName);
        cameraTexture.Play();

        // Initialize camera material with chroma key shader
        chromaKeyMaterial = new Material(Shader.Find("Unlit/ChromaKeyShader"));
        chromaKeyMaterial.mainTexture = cameraTexture;
    }

    private static string[] getCameraNames()
    {
        // Get all connected Webcam devices and initialize output array
        WebCamDevice[] devices = WebCamTexture.devices;
        string[] names = new string[devices.Length + 1];
        names[0] = "Please Select your Webcam...";

        // Find the correct Webcam device to add it's texture to rawImage
        for (var i = 0; i < devices.Length; i++)
        {
            names[i + 1] = devices[i].name;
        }

        return names;
    }
}