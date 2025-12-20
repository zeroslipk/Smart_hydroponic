# How to Move Android SDK to D: Drive

## Steps to Move Android SDK:

1. **Close Android Studio completely**

2. **Move the SDK folder:**
   - Current location: `C:\Users\DELL\AppData\Local\Android\sdk`
   - New location: `D:\Android\sdk`
   - Copy the entire `sdk` folder to `D:\Android\`

3. **Update Android Studio Settings:**
   - Open Android Studio
   - Go to **File → Settings** (or **Tools → SDK Manager**)
   - Go to **Languages & Frameworks → Android SDK**
   - Click **Edit** next to "Android SDK Location"
   - Change from: `C:\Users\DELL\AppData\Local\Android\sdk`
   - Change to: `D:\Android\sdk`
   - Click **OK**

4. **Update local.properties:**
   - In your project: `aquagrow_app/android/local.properties`
   - Change: `sdk.dir=C:\\Users\\DELL\\AppData\\Local\\Android\\sdk`
   - To: `sdk.dir=D:\\Android\\sdk`

5. **Delete old SDK folder** (after confirming new location works):
   - Delete: `C:\Users\DELL\AppData\Local\Android\sdk`

## Alternative: Use Symbolic Link

If you prefer to keep the SDK path the same but store it on D: drive:

```powershell
# Run as Administrator
mklink /D "C:\Users\DELL\AppData\Local\Android\sdk" "D:\Android\sdk"
```

Then move the SDK folder to D:\Android\sdk






