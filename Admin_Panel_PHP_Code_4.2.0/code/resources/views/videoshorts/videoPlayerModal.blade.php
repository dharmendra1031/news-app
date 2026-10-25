<div class="modal fade" id="videoPlayerModal" tabindex="-1" role="dialog" aria-labelledby="videoPlayerTitle" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="videoPlayerTitle">{{ __('video_preview') }}</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="{{ __('close') }}">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body p-0 bg-dark">
                <video id="videoPlayerEl" controls
                    style="width:100%; max-height:70vh; display:block; background:#000;"
                    preload="metadata">
                </video>
                <div id="videoPlayerFallback" class="text-center py-5 px-4" style="display:none;">
                    <i class="fas fa-film fa-3x text-secondary mb-3"></i>
                    <p class="text-white mb-3">{{ __('browser_cannot_play') }}</p>
                    <a id="videoPlayerDownload" href="#" class="btn btn-primary" download>
                        <i class="fas fa-download mr-1"></i>{{ __('download') }}
                    </a>
                </div>
                <iframe
                    id="youtubePlayerEl"
                    width="100%"
                    height="450"
                    style="display:none;"
                    frameborder="0"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                    allowfullscreen>
                </iframe>   
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ __('close') }}</button>
            </div>
        </div>
    </div>
</div>
