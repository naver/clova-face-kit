// reference: https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Taking_still_photos

function process(clova) {
  // The width and height of the captured photo. We will set the
  // width to the value defined here, but the height will be
  // calculated based on the aspect ratio of the input stream.

  var width = 320;    // We will scale the photo width to this
  var height = 0;     // This will be computed based on the input stream

  // |streaming| indicates whether or not we're currently streaming
  // video from the camera. Obviously, we start at false.

  var streaming = false;

  // The various HTML elements we need to configure or control. These
  // will be set by the startup() function.
  var video = document.getElementById('video');
  var canvas = document.getElementById('canvas');
  var photo = document.getElementById('photo');
  var startbutton = document.getElementById('startbutton');

  let resources = new clova.Resources('clovasee.all.bundle');
  let settings = new clova.SettingsBuilder()
                          .setPerformanceMode(clova.PerformanceMode.ACCURATE106)
                          .build();
  let clovaSee = new clova.ClovaSee(settings, resources);

  var masks = [
    document.createElement("img"),
    document.createElement("img"),
    document.createElement("img"),
  ]
  masks.forEach((item, idx) => {
    item.src = "./mask_" + idx + ".png";
  });
  masks.push(document.createElement("img"));

  function startup() {
    navigator.mediaDevices.getUserMedia(
      {
        video: {width: {exact: 640}, height: {exact: 360}},
        audio: false
      }
    ).then(function(stream) {
      video.srcObject = stream;
      video.play();
    }).catch(function(err) {
      console.log("An error occurred: " + err);
    });

    video.addEventListener('canplay', function(ev){
      if (!streaming) {
        height = video.videoHeight / (video.videoWidth/width);
      
        // Firefox currently has a bug where the height can't be read from
        // the video, so we will make assumptions if this happens.
      
        if (isNaN(height)) {
          height = width / (4/3);
        }
      
        video.setAttribute('width', width);
        video.setAttribute('height', height);
        canvas.setAttribute('width', width);
        canvas.setAttribute('height', height);
        streaming = true;
      }
    }, false);

    requestAnimationFrame(takepicture);
  }

  // Fill the photo with an indication that none has been
  // captured.

  function clearphoto() {
    var context = canvas.getContext('2d');
    context.fillStyle = "#AAA";
    context.fillRect(0, 0, canvas.width, canvas.height);

    var data = canvas.toDataURL('image/png');
    photo.setAttribute('src', data);
  }
  
  // Capture a photo by fetching the current contents of the video
  // and drawing it into a canvas, then converting that to a PNG
  // format data URL. By drawing it on an offscreen canvas and then
  // drawing that to the screen, we can change its size and/or apply
  // other changes before drawing it.

  function drawContour(context, face) {
    var points = face.contour().points;
    context.fillStyle = 'red';
    for (index = 0; index < points.size(); index++) {
      var point = points.get(index);
      context.fillRect(point.x, point.y, 2, 2);
    }
  }

  function drawBoundingBox(context, face) {
    var boundingBox = face.boundingBox();
    context.strokeRect(
      boundingBox.x, boundingBox.y, boundingBox.width, boundingBox.height);
  }

  function drawAngle(context, face) {
    var angle = face.eulerAngle();
    var boundingBox = face.boundingBox();
    context.fillText(`x=${angle.x.toFixed(2)} y=${angle.y.toFixed(2)} z=${angle.z.toFixed(2)}`, boundingBox.leftBottom().x, boundingBox.leftBottom().y);
  }

  function drawMask(context, face, mask) {
    var boundingBox = face.boundingBox();
    context.drawImage(mask,
      boundingBox.x,
      boundingBox.y,
      boundingBox.width,
      boundingBox.height);
  }

  function takepicture() {
    var context = canvas.getContext('2d');
    if (width && height) {
      canvas.width = width;
      canvas.height = height;
      context.drawImage(video, 0, 0, width, height);

      var imgData = context.getImageData(0, 0, width, height);

      var frame = new clova.Frame(imgData.data,
                                  width,
                                  height,
                                  clova.Format.RGBA_8888);

      var getContour = document.getElementById('contour').checked;
      var getAngle = document.getElementById('angle').checked;

      var flag = clova.BOUNDING_BOXES;
      if(getContour) {
        flag |= clova.CONTOURS;
      }
      if(getAngle) {
        flag |= clova.EULER_ANGLES;
      }

      var options = new clova.FaceOptionsBuilder()
                             .setInformationToObtain(flag)
                             .build();
      var faces = clovaSee.runForFace(frame, options).faces();
      
      context.lineWidth = 1.5;
      context.strokeStyle = 'red';
      var idx = document.querySelector('input[name="selector"]:checked').value;
      for (var i=0; i < faces.size(); ++i) {
        var face = faces.get(i);
        drawBoundingBox(context, face);
        drawMask(context, face, masks[idx]);
        if(getContour) drawContour(context, face);
        if(getAngle) drawAngle(context, face);
      }
    
      var data = canvas.toDataURL('image/png');
      photo.setAttribute('src', data);

    } else {
      clearphoto();
    }

    requestAnimationFrame(takepicture);
  }

  // Set up our event listener to run the startup process
  // once loading is complete.
  startbutton.addEventListener('click', function(ev){
    startbutton.disabled = true;
    startup();
    ev.preventDefault();
  }, false);
  clearphoto();
}

clova().then(
  (instance) => {
    console.log('Wasm Loaded!');
    process(instance);
  }
);
