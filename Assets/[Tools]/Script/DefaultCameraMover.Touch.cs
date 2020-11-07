
public partial class DefaultCameraMover : LoadableBehaviour
{
    public bool TouchTranslation = true;
    public bool TouchRotationX = false;
    public bool TouchRotationY = false;
    public bool TouchZoom = true;
    private TouchInfo mouseTouchInfo = new TouchInfo();
    private TouchInfo previousMouseTouchInfo = new TouchInfo();
    private TouchInfo[] touchInfos = new TouchInfo[2];
    private TouchInfo[] previousTouchInfos = new TouchInfo[2];

    public UnityEngine.Vector3 GetIntersectionPoint(UnityEngine.Vector2 screenPosition)
    {
        UnityEngine.Ray ray = this.usedCamera.ScreenPointToRay(screenPosition);
        UnityEngine.Vector3 hitPos = UnityEngine.Vector3.zero;
        if ((ray.direction.y < 0) == (ray.origin.y > 0))
        {
            hitPos = ray.origin - ray.direction * (ray.origin.y / ray.direction.y);
        }

        return hitPos;
    }

    protected void OnGUI()
    {
        UnityEngine.Vector2 boxSize = UnityEngine.Vector2.one * 50;
        UnityEngine.Color previousGUIColor = UnityEngine.GUI.color;
        for (int i = 0; i < touchInfos.Length; ++i)
        {
            if (this.touchInfos[i].FingerId != -1)
            {
                UnityEngine.Vector2 uiConventionPos = new UnityEngine.Vector2(this.touchInfos[i].ScreenPos.x, UnityEngine.Screen.height - this.touchInfos[i].ScreenPos.y);
                UnityEngine.Rect touchRect0 = new UnityEngine.Rect(uiConventionPos - boxSize * 0.5f, boxSize);
                UnityEngine.GUI.color = new UnityEngine.Color(i == 0 ? 1 : 0, i == 1 ? 1 : 0, i == 2 ? 1 : 0, 1);
                UnityEngine.GUI.DrawTexture(touchRect0, UnityEngine.Texture2D.whiteTexture);
                UnityEngine.GUI.color = UnityEngine.Color.black;
                UnityEngine.GUI.Label(touchRect0, this.touchInfos[i].FingerId.ToString());
            }
        }

        UnityEngine.GUI.color = previousGUIColor;
    }

    protected void HandleTouch()
    {
        int touchCountMax = this.touchInfos.Length;
        for (int i = 0; i < touchCountMax; ++i)
        {
            this.previousTouchInfos[i] = new TouchInfo();
        }

        int touchCount = UnityEngine.Mathf.Min(touchCountMax, UnityEngine.Input.touchCount);
        for (int i = 0; i < touchCount; ++i)
        {
            int sameFinger = -1;
            UnityEngine.Touch touch = UnityEngine.Input.GetTouch(i);
            for (int previousInputId = 0; previousInputId < touchCountMax; ++previousInputId)
            {
                if (this.touchInfos[previousInputId].SameFingerID(ref touch))
                {
                    sameFinger = previousInputId;
                }
            }

            if (sameFinger != -1)
            {
                this.previousTouchInfos[i] = this.touchInfos[sameFinger];
            }
            else
            {
                this.previousTouchInfos[i] = new TouchInfo();
            }
        }

        this.previousMouseTouchInfo = this.mouseTouchInfo;

        for (int i = 0; i < touchCount; ++i)
        {
            UnityEngine.Touch touch = UnityEngine.Input.GetTouch(i);
            this.touchInfos[i] = new TouchInfo(ref touch, this);
        }

        UnityEngine.TouchPhase mouseTouchPhase = UnityEngine.Input.GetMouseButton(0) ? (UnityEngine.Input.GetMouseButtonDown(0) ? UnityEngine.TouchPhase.Began : UnityEngine.TouchPhase.Moved) : UnityEngine.TouchPhase.Ended;
        this.mouseTouchInfo = new TouchInfo()
        {
            ScreenPos = UnityEngine.Input.mousePosition,
            HitPos = GetIntersectionPoint(UnityEngine.Input.mousePosition),
            Phase = mouseTouchPhase
        };

        for (int i = touchCount; i < touchCountMax; ++i)
        {
            this.touchInfos[i] = new TouchInfo();
        }

        if (touchCount == 0 && this.mouseTouchInfo.Phase == UnityEngine.TouchPhase.Moved && this.TouchTranslation)
        {
            UnityEngine.Ray ray = this.usedCamera.ScreenPointToRay(this.mouseTouchInfo.ScreenPos);
            float previousHeight = this.transform.position.y;
            UnityEngine.Vector3 nextPosition = this.previousMouseTouchInfo.HitPos + ray.direction * (previousHeight / ray.direction.y);
            nextPosition.y = previousHeight;
            this.transform.position = nextPosition;
        }

        if (touchCount == 1)
        {
            if (this.touchInfos[0].Phase == UnityEngine.TouchPhase.Moved &&
                this.previousTouchInfos[0].FingerId != -1 &&
                this.TouchTranslation)
            {
                UnityEngine.Ray ray = this.usedCamera.ScreenPointToRay(this.touchInfos[0].ScreenPos);
                float previousHeight = this.transform.position.y;
                UnityEngine.Vector3 nextPosition = this.previousTouchInfos[0].HitPos + ray.direction * (previousHeight / ray.direction.y);
                nextPosition.y = previousHeight;
                this.transform.position = nextPosition;
            }
        }

        if (touchCount == 2)
        {
            if ((this.touchInfos[0].Phase == UnityEngine.TouchPhase.Moved || this.touchInfos[1].Phase == UnityEngine.TouchPhase.Moved) &&
                (this.previousTouchInfos[0].FingerId != -1 && this.previousTouchInfos[1].FingerId != -1))
            {
                UnityEngine.Vector3 previousDifHitPos = this.previousTouchInfos[0].HitPos - this.previousTouchInfos[1].HitPos;
                float previousDistance01 = UnityEngine.Vector3.Magnitude(previousDifHitPos);
                UnityEngine.Vector3 difHitPos = this.touchInfos[0].HitPos - this.touchInfos[1].HitPos;
                float currentDistance01 = UnityEngine.Vector3.Magnitude(difHitPos);

                UnityEngine.Vector3 nextPosition = this.transform.position;
                UnityEngine.Vector2 middleScreenPoint = (this.touchInfos[0].ScreenPos + this.touchInfos[1].ScreenPos) * 0.5f;
                UnityEngine.Ray ray = this.usedCamera.ScreenPointToRay(middleScreenPoint);
                nextPosition -= ray.direction * (previousDistance01 - currentDistance01);
                if (this.TouchZoom)
                {
                    this.transform.position = nextPosition;
                }

                float deltaAngleAroundY = 0;
                {
                    UnityEngine.Vector2 difScreenPos = this.touchInfos[0].ScreenPos - this.touchInfos[1].ScreenPos;
                    UnityEngine.Vector2 previousDifScreenPos = this.previousTouchInfos[0].ScreenPos - this.previousTouchInfos[1].ScreenPos;
                    float currentAngle = UnityEngine.Mathf.Atan2(difScreenPos.y, difScreenPos.x);
                    float previousAngle = UnityEngine.Mathf.Atan2(previousDifScreenPos.y, previousDifScreenPos.x);
                    deltaAngleAroundY += (currentAngle - previousAngle) * 180f / UnityEngine.Mathf.PI;
                }

                float deltaAngleX = 0;
                UnityEngine.Vector2 previousMiddlePoint = (this.previousTouchInfos[0].ScreenPos + this.previousTouchInfos[1].ScreenPos) * 0.5f;

                {
                    UnityEngine.Vector2 modifiedPreviousMiddlePoint = previousMiddlePoint;
                    modifiedPreviousMiddlePoint.x = middleScreenPoint.x;
                    UnityEngine.Ray previousRay = this.usedCamera.ScreenPointToRay(modifiedPreviousMiddlePoint);
                    float absDeltaAngleX = UnityEngine.Vector3.Angle(previousRay.direction, ray.direction);
                    deltaAngleX += (previousMiddlePoint.y < middleScreenPoint.y) ? absDeltaAngleX : -absDeltaAngleX;
                }
                
                float deltaAngleY = 0;
                {
                    //UnityEngine.Vector2 modifiedPreviousMiddlePoint = previousMiddlePoint;
                    //UnityEngine.Ray previousRay = this.usedCamera.ScreenPointToRay(modifiedPreviousMiddlePoint);
                    //UnityEngine.Vector3 projectedPreviousRayDirection = previousRay.direction;
                    //projectedPreviousRayDirection.y = 0;
                    //UnityEngine.Vector3 projectedRayDirection = previousRay.direction;
                    //projectedRayDirection.y = 0;
                    //float absDeltaAngleY = UnityEngine.Vector3.Angle(this.transform.forward, previousRay.direction);

                    //deltaAngleY += (previousMiddlePoint.x < middleScreenPoint.x) ? absDeltaAngleY : -absDeltaAngleY;
                }

                if (deltaAngleAroundY != 0 || 
                    deltaAngleX != 0 ||
                    deltaAngleY != 0)
                {
                    UnityEngine.Vector3 rotateAround = GetIntersectionPoint(middleScreenPoint);
                    UnityEngine.Vector3 nextEulerAngles = this.transform.eulerAngles;
                    nextEulerAngles.y += deltaAngleAroundY;
                    this.transform.eulerAngles = nextEulerAngles;
                    UnityEngine.Ray nextRay = this.usedCamera.ScreenPointToRay(middleScreenPoint);
                    float originalDistance = UnityEngine.Vector3.Magnitude(rotateAround - this.transform.position);
                    this.transform.position = rotateAround - originalDistance * nextRay.direction;

                    nextEulerAngles.x += this.TouchRotationX ? deltaAngleX : 0;
                    nextEulerAngles.y += this.TouchRotationY ? deltaAngleY : 0;
                    this.transform.eulerAngles = nextEulerAngles;
                }
            }
        }
        
        for (int i = 0; i < touchCount; ++i)
        {
            UnityEngine.Touch touch = UnityEngine.Input.GetTouch(i);
            this.touchInfos[i] = new TouchInfo(ref touch, this);
        }

        this.mouseTouchInfo = new TouchInfo()
        {
            ScreenPos = UnityEngine.Input.mousePosition,
            HitPos = GetIntersectionPoint(UnityEngine.Input.mousePosition),
            Phase = mouseTouchPhase
        };
    }

    public struct TouchInfo
    {
        public UnityEngine.Vector2 ScreenPos;
        public UnityEngine.Vector3 HitPos;
        public UnityEngine.TouchPhase Phase;
        private int fingerIdOffseted;

        public int FingerId
        {
            get { return this.fingerIdOffseted - 1; }
        }

        public TouchInfo(ref UnityEngine.Touch touch, DefaultCameraMover cameraMover)
        {
            this.ScreenPos = touch.position;
            this.fingerIdOffseted = touch.fingerId + 1;
            this.HitPos = cameraMover.GetIntersectionPoint(touch.position);
            this.Phase = touch.phase;
        }

        public bool SameFingerID(ref UnityEngine.Touch touch)
        {
            return (touch.fingerId + 1) == this.fingerIdOffseted;
        }
    }
}
